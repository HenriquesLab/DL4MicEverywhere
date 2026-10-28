#!/usr/bin/env python3
"""DL4MicEverywhere image build/import/GPU diagnostic runner.

Drop-in replacement for .tools/python_tools/build_and_test_images.py on improve_gui.
Preserves existing CLI and JSON result structure; adds GPU execution diagnostics,
network-error classification and more conservative runtime-install warnings.

Run from Linux/WSL/macOS with Docker:
  python3 .tools/python_tools/build_and_test_images.py --variant both
  python3 .tools/python_tools/build_and_test_images.py --only Detectron2 --variant cpu
"""
from __future__ import annotations

import argparse
import datetime as dt
import importlib.util
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TAG_PREFIX = "dl4me-image-test"
IMPORT_MARKER = "DL4ME_IMPORT_REPORT:"
GPU_MARKER = "DL4ME_GPU_REPORT:"

spec = importlib.util.spec_from_file_location("requirements_lock", Path(__file__).with_name("requirements_lock.py"))
lock_util = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(lock_util)

# This code runs inside the image, including legacy Python 3.5/3.6.
IMPORT_CODE = r'''
import ast
import json
import os
import re
import sys
os.environ.setdefault("MPLBACKEND", "Agg")
marker = "DL4ME_IMPORT_REPORT:"
install_re = re.compile(r"(?:pip3?|conda|mamba)\s+install|git\s+clone|setup\.py\s+(?:install|develop)|\b(?:wget|curl)\s", re.I)
install_commands = []
imports = []
notebook = json.load(open(sys.argv[1], encoding="utf-8"))

def collect(nodes, optional=False):
    for node in nodes:
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(("import " + alias.name, optional))
            continue
        if isinstance(node, ast.ImportFrom):
            if node.level == 0 and node.module:
                imports.append(("from %s import %s" % (node.module, ", ".join(a.name for a in node.names)), optional))
            continue
        if node.__class__.__name__ in ("Try", "TryExcept", "TryFinally", "TryStar"):
            collect(getattr(node, "body", []), True)
            for handler in getattr(node, "handlers", []):
                collect(handler.body, True)
            collect(getattr(node, "orelse", []), optional)
            collect(getattr(node, "finalbody", []), optional)
            continue
        for field in ("body", "orelse", "finalbody"):
            collect(getattr(node, field, []) or [], optional)

line_re = re.compile(r"^\s*((?:import|from)\s+[A-Za-z_][\w.]*.*)$")
for cell in notebook.get("cells", []):
    if cell.get("cell_type") != "code":
        continue
    src = cell.get("source", "")
    if isinstance(src, list):
        src = "".join(src)
    lines = []
    for line in src.splitlines():
        if line.lstrip().startswith(("!", "%")):
            if install_re.search(line) and "uninstall" not in line:
                install_commands.append(line.strip())
        else:
            lines.append(line)
    code = "\n".join(lines)
    try:
        collect(ast.parse(code).body)
    except SyntaxError:
        for line in code.splitlines():
            match = line_re.match(line)
            if match:
                imports.append((match.group(1).split("#")[0].strip(), False))

results = []
seen = set()
for statement, optional in imports:
    if statement in seen:
        continue
    seen.add(statement)
    entry = {"statement": statement, "optional": optional, "runtime": False,
             "ok": True, "error": "", "classification": "ok"}
    try:
        exec(statement, {})
    except BaseException as exc:
        entry["ok"] = False
        entry["error"] = "%s: %s" % (exc.__class__.__name__, exc)
        module = statement.split()[1].split(".")[0]
        missing = (getattr(exc, "name", None) or "").split(".")[0]
        # Runtime hypothesis is *unverified*. Do not claim the commands install it.
        runtime_candidate = (bool(install_commands) and not optional and
                             isinstance(exc, ImportError) and module == missing and
                             module != "google")
        entry["runtime"] = runtime_candidate
        entry["classification"] = ("optional" if optional else
                                   "runtime_candidate_unverified" if runtime_candidate else
                                   "required_missing_or_broken")
    results.append(entry)
print("\n" + marker + json.dumps({"imports": results, "install_commands": install_commands}))
sys.stdout.flush()
if any(not x["ok"] and not x["optional"] and not x["runtime"] for x in results):
    sys.exit(1)
'''

# Actual GPU execution rather than mere device enumeration. Python 3.5-compatible.
# Uses explicit placement to prevent TensorFlow silently falling back to CPU.
GPU_CODE = r'''
import json
import sys
import traceback
result = {"frameworks": {}, "notes": []}

def note(framework, status, detail):
    result["frameworks"][framework] = {"status": status, "detail": detail}

try:
    import tensorflow as tf
except ImportError:
    note("tensorflow", "SKIP", "Not installed")
except BaseException as exc:
    note("tensorflow", "FAIL", "Import error: %s: %s" % (type(exc).__name__, exc))
else:
    version = getattr(tf, "__version__", "unknown")
    try:
        if version.split(".")[0] == "1":
            conf = tf.ConfigProto(allow_soft_placement=False, log_device_placement=False)
            with tf.Graph().as_default():
                with tf.device("/device:GPU:0"):
                    a = tf.constant([[1., 2.], [3., 4.]])
                    product = tf.matmul(a, a)
                with tf.Session(config=conf) as sess:
                    sess.run(product)
        else:
            # TF2 may be invoked in v1 graph mode by some notebooks.
            gpus = tf.config.list_physical_devices("GPU")
            if not gpus:
                raise RuntimeError("TensorFlow lists no GPU devices")
            with tf.device("/GPU:0"):
                a = tf.constant([[1., 2.], [3., 4.]])
                out = tf.matmul(a, a)
                if hasattr(out, "numpy"):
                    out.numpy()
                else:
                    with tf.compat.v1.Session(config=tf.compat.v1.ConfigProto(allow_soft_placement=False)) as sess:
                        sess.run(out)
        note("tensorflow", "PASS", "GPU matrix multiplication succeeded; version=" + version)
    except BaseException as exc:
        note("tensorflow", "FAIL", "GPU execution failed; version=%s; %s: %s" % (version, type(exc).__name__, exc))
        traceback.print_exc()

try:
    import torch
except ImportError:
    note("pytorch", "SKIP", "Not installed")
except BaseException as exc:
    note("pytorch", "FAIL", "Import error: %s: %s" % (type(exc).__name__, exc))
else:
    try:
        if not torch.cuda.is_available():
            raise RuntimeError("torch.cuda.is_available() is False")
        a = torch.tensor([[1., 2.], [3., 4.]], device="cuda:0")
        out = torch.mm(a, a)
        torch.cuda.synchronize()
        out.cpu()
        note("pytorch", "PASS", "GPU matrix multiplication succeeded; version=" + torch.__version__)
    except BaseException as exc:
        note("pytorch", "FAIL", "GPU execution failed; %s: %s" % (type(exc).__name__, exc))
        traceback.print_exc()

print("\nDL4ME_GPU_REPORT:" + json.dumps(result))
sys.stdout.flush()
if any(item["status"] == "FAIL" for item in result["frameworks"].values()):
    sys.exit(1)
'''


def now():
    return dt.datetime.now().isoformat(timespec="seconds")


def config_value(path, key, default=None):
    try:
        return lock_util.parse_config_value(path, key)
    except ValueError:
        if default is None:
            raise
        return default


def slug(path):
    return re.sub(r"[^a-z0-9_.-]+", "-", path.parent.name.lower()).strip("-.") or "notebook"


def run(command, logpath, timeout=None):
    start = time.monotonic()
    with logpath.open("a", encoding="utf-8") as log:
        log.write("$ " + " ".join(command[:12]) + (" [...]" if len(command) > 12 else "") + "\n")
        log.flush()
        try:
            status = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                    timeout=timeout, check=False).returncode
        except subprocess.TimeoutExpired:
            log.write("TIMEOUT after %s seconds\n" % timeout)
            status = 124
        except OSError as exc:
            log.write("Command failure: %s\n" % exc)
            status = 125
    return status, round(time.monotonic() - start, 1)


def parse_marker(path, marker):
    if not path.exists():
        return None
    for line in reversed(path.read_text(encoding="utf-8", errors="replace").splitlines()):
        if marker in line:
            try:
                return json.loads(line.split(marker, 1)[1])
            except ValueError:
                return None
    return None


def classify_failure(path, step):
    if not path.exists():
        return "unknown"
    content = path.read_text(encoding="utf-8", errors="replace").lower()
    if "timeout after" in content:
        return "timeout"
    if any(x in content for x in ("could not connect", "temporary failure in name resolution",
                                  "connection refused", "connection timed out", "network is unreachable")):
        return "network_or_repository_connectivity"
    if "hashes do not match" in content or "hash mismatch" in content:
        return "package_hash_mismatch"
    if "unable to locate package libcudnn" in content:
        return "cudnn_package_unavailable_or_repository_failure"
    if "no module named" in content or "modulenotfounderror" in content:
        return "missing_python_module"
    if step == "gpu":
        return "gpu_framework_execution"
    return "see_log"


class Plan:
    def __init__(self, config, gpu, platform):
        self.config = config
        self.gpu = gpu
        self.platform = platform
        self.relative = config.relative_to(ROOT).as_posix()
        self.python = config_value(config, "python_version")
        self.ubuntu = config_value(config, "ubuntu_version")
        self.cuda = config_value(config, "cuda_version", "")
        self.cudnn = config_value(config, "cudnn_version", "")
        self.url = config_value(config, "notebook_url")
        self.requirements_url = config_value(config, "requirements_url", "")
        self.sections = config_value(config, "sections_to_remove", "")
        self.name = self.url.rstrip("/").split("/")[-1]
        self.variant = "gpu" if gpu else "cpu"
        suffix = ".legacy" if self.python in ("3.5", "3.6") else ".modern"
        self.dockerfile = "docker/Dockerfile" + (".gpu" if gpu else "") + suffix
        self.tag = "%s:%s-%s" % (TAG_PREFIX, slug(config), self.variant)
        self.lock = lock_util.default_lock_path(config, platform).relative_to(ROOT.resolve()).as_posix()

    def build(self, bases):
        params = {
            "CONVERTER_BASE_IMAGE": bases["converter_base_image"],
            "FINAL_BASE_IMAGE": bases["final_base_image"],
            "UBUNTU_VERSION": self.ubuntu,
            "CUDA_VERSION": self.cuda,
            "CUDNN_VERSION": self.cudnn,
            "GPU_FLAG": "1" if self.gpu else "0",
            "PYTHON_VERSION": self.python,
            "PATH_TO_NOTEBOOK": self.url,
            "PATH_TO_REQUIREMENTS": self.requirements_url,
            "PATH_TO_REQUIREMENTS_LOCK": self.lock,
            "NOTEBOOK_NAME": self.name,
            "SECTIONS_TO_REMOVE": self.sections,
        }
        cmd = ["docker", "build", "--progress=plain", "--file", self.dockerfile, "-t", self.tag,
               "--label", "org.dl4miceverywhere.managed=true",
               "--label", "org.dl4miceverywhere.image-test=true"]
        for key, value in params.items():
            cmd += ["--build-arg", "%s=%s" % (key, value)]
        return cmd + ["."]

    def docker_run(self, code, extra=None):
        cmd = ["docker", "run", "--rm"]
        if self.gpu:
            cmd += ["--gpus", "all"]
        cmd += [self.tag, "python", "-c", code]
        return cmd + (extra or [])


def empty_imports():
    return {"total": 0, "failed": [], "optional_failed": [], "runtime_failed": [], "install_commands": []}


def test_one(plan, logdir, args):
    stem = slug(plan.config) + "-" + plan.variant
    logs = {key: logdir / (stem + "-" + key + ".log") for key in
            ("prepare", "build", "smoke", "imports", "gpu")}
    result = {"config": plan.relative, "variant": plan.variant, "python": plan.python,
              "image": plan.tag, "started": now(), "status": "FAIL", "failed_step": "",
              "failure_category": "", "steps": {}, "imports": empty_imports(),
              "gpu": {}, "image_size_gb": None,
              "logs": {k: p.relative_to(logdir.parent).as_posix() for k, p in logs.items()}}

    def step(name, code, secs):
        result["steps"][name] = {"ok": code == 0, "seconds": secs}
        if code and not result["failed_step"]:
            result["failed_step"] = name
            result["failure_category"] = classify_failure(logs[name], name)
        return code == 0

    python = sys.executable
    code, elapsed = run([python, ".tools/python_tools/requirements_lock.py", "ensure", "--config",
                         plan.relative, "--platform", plan.platform, "--repo-root", "."], logs["prepare"])
    if code == 0:
        code2, secs = run([python, ".tools/python_tools/requirements_lock.py", "ensure", "--source",
                           "docker/converter-requirements.txt", "--python-version", "3.9", "--lock",
                           "docker/converter-requirements.lock.txt", "--profile", "none", "--repo-root", "."],
                          logs["prepare"])
        code, elapsed = code2, elapsed + secs
    bases = None
    if code == 0:
        start = time.monotonic()
        proc = subprocess.run([python, ".tools/python_tools/base_image_lock.py", "--repo-root", ".",
                               "ensure-for-build", "--config", plan.relative,
                               "--gpu", "1" if plan.gpu else "0"], cwd=ROOT, capture_output=True, text=True)
        with logs["prepare"].open("a", encoding="utf-8") as log:
            log.write(proc.stdout + proc.stderr)
        code, elapsed = proc.returncode, elapsed + round(time.monotonic() - start, 1)
        if not code:
            try:
                bases = json.loads(proc.stdout.strip().splitlines()[-1])
            except (ValueError, IndexError):
                code = 1
    if not step("prepare", code, elapsed):
        return result

    code, secs = run(plan.build(bases), logs["build"], args.build_timeout * 60)
    if not step("build", code, secs):
        return result

    size = subprocess.run(["docker", "image", "inspect", "--format", "{{.Size}}", plan.tag],
                          capture_output=True, text=True).stdout.strip()
    if size.isdigit():
        result["image_size_gb"] = round(int(size) / 1e9, 2)

    code, secs = run(["bash", ".tools/bash_tools/post_build_test.sh", plan.tag,
                      "1" if plan.gpu else "0", "1"], logs["smoke"], args.test_timeout * 60)
    step("smoke", code, secs)

    code, secs = run(plan.docker_run(IMPORT_CODE, ["/home/" + plan.name]), logs["imports"],
                     args.test_timeout * 60)
    parsed = parse_marker(logs["imports"], IMPORT_MARKER)
    if parsed is not None:
        entries = parsed.get("imports", [])
        result["imports"] = {
            "total": len(entries),
            "failed": [x for x in entries if not x["ok"] and not x["optional"] and not x["runtime"]],
            "optional_failed": [x for x in entries if not x["ok"] and x["optional"]],
            "runtime_failed": [x for x in entries if not x["ok"] and x["runtime"]],
            "install_commands": parsed.get("install_commands", []),
        }
    else:
        code = code or 1
    step("imports", code, secs)

    # Run even if smoke fails; diagnostic evidence must not be lost.
    if plan.gpu:
        code, secs = run(plan.docker_run(GPU_CODE), logs["gpu"], args.test_timeout * 60)
        parsed = parse_marker(logs["gpu"], GPU_MARKER)
        result["gpu"] = parsed or {"error": "No structured GPU report (possibly Docker passthrough failed)"}
        if parsed is None:
            code = code or 1
        step("gpu", code, secs)

    if not result["failed_step"]:
        result["status"] = "WARN" if (result["imports"]["optional_failed"] or
                                     result["imports"]["runtime_failed"]) else "PASS"
    return result


def write_reports(folder, results, meta):
    (folder / "report.json").write_text(json.dumps({"meta": meta, "results": results}, indent=2) + "\n",
                                        encoding="utf-8")
    counts = {s: sum(x["status"] == s for x in results) for s in ("PASS", "WARN", "FAIL")}
    lines = ["# DL4MicEverywhere image testing report", "", "Started: %s  " % meta["started"],
             "Finished: %s  " % meta.get("finished", "running"),
             "Platform: linux/%s  " % meta["platform"],
             "Planned: %s | Completed: %s  " % (meta["planned"], len(results)),
             "**%s PASS, %s WARN, %s FAIL**" % (counts["PASS"], counts["WARN"], counts["FAIL"]),
             "", "WARN means optional imports or **unverified** runtime-install candidates; "
             "the notebook's commands have NOT been executed.", "",
             "| Notebook | Variant | Python | Result | Failed step | Cause | GPU execution | Imports | Logs |",
             "|---|---|---|---|---|---|---|---|---|"]
    for r in results:
        imp = r.get("imports", empty_imports())
        failures = len(imp["failed"]) + len(imp["optional_failed"]) + len(imp["runtime_failed"])
        imports = "%d/%d" % (imp["total"] - failures, imp["total"]) if "imports" in r["steps"] else "-"
        gpu = r.get("gpu", {}).get("frameworks", {})
        gpu_text = ", ".join("%s:%s" % (k, v["status"]) for k, v in gpu.items()) or "-"
        links = " ".join("[%s](%s)" % (k, v) for k, v in r.get("logs", {}).items()
                         if (folder / v).exists())
        fields = [Path(r["config"]).parent.name, r["variant"], r["python"], r["status"],
                  r["failed_step"] or "-", r.get("failure_category") or "-", gpu_text, imports, links]
        lines.append("| " + " | ".join(str(v).replace("|", "\\|") for v in fields) + " |")
    lines += ["", "## Detailed failures and warnings", ""]
    for r in results:
        if r["status"] == "PASS":
            continue
        lines.append("### %s (%s) — %s" % (Path(r["config"]).parent.name, r["variant"], r["status"]))
        if r["failed_step"]:
            lines.append("- Failed step: **%s**; classification: **%s**" %
                         (r["failed_step"], r.get("failure_category", "unknown")))
        for group, title in (("failed", "Required import failure"),
                             ("runtime_failed", "Runtime install candidate, NOT verified"),
                             ("optional_failed", "Optional import")):
            for item in r["imports"][group]:
                lines.append("- %s: `%s` — %s" % (title, item["statement"], item["error"]))
        for framework, check in r.get("gpu", {}).get("frameworks", {}).items():
            if check["status"] == "FAIL":
                lines.append("- %s GPU: %s" % (framework, check["detail"]))
        lines.append("")
    (folder / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--variant", choices=("cpu", "gpu", "both"), default="cpu")
    parser.add_argument("--output-dir", default="image_test_reports")
    parser.add_argument("--keep-images", action="store_true")
    parser.add_argument("--keep-build-cache", action="store_true")
    parser.add_argument("--build-timeout", type=int, default=120)
    parser.add_argument("--test-timeout", type=int, default=30)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    configs = sorted((ROOT / "notebooks").rglob("configuration.yaml"))
    if args.only:
        configs = [x for x in configs if any(y.lower() in str(x.relative_to(ROOT)).lower() for y in args.only)]
    if not configs:
        parser.error("No configuration.yaml files matched")
    variants = {"cpu": [False], "gpu": [True], "both": [False, True]}[args.variant]
    if args.dry_run:
        for config in configs:
            for gpu in variants:
                plan = Plan(config, gpu, "amd64")
                print("%s: %s -> %s" % (plan.relative, plan.dockerfile, plan.tag))
        return 0
    for executable in ("docker", "bash"):
        if not shutil.which(executable):
            parser.error("%s is required" % executable)
    if subprocess.run(["docker", "info"], capture_output=True).returncode:
        parser.error("Docker is not running or accessible")
    arch = subprocess.run(["docker", "info", "--format", "{{.Architecture}}"],
                          capture_output=True, text=True).stdout.strip()
    platform = "arm64" if arch in ("arm64", "aarch64") else "amd64"
    output_base = Path(args.output_dir)
    folder = (output_base if output_base.is_absolute() else ROOT / output_base) / dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    logdir = folder / "logs"
    logdir.mkdir(parents=True)
    meta = {"started": now(), "platform": platform, "variants": ["gpu" if x else "cpu" for x in variants],
            "planned": len(configs) * len(variants)}
    results = []
    interrupted = False
    for config in configs:
        for gpu in variants:
            plan = None
            try:
                plan = Plan(config, gpu, platform)
                print("Testing %s (%s)" % (plan.relative, plan.variant), flush=True)
                result = test_one(plan, logdir, args)
            except KeyboardInterrupt:
                interrupted = True
                break
            except (OSError, ValueError, RuntimeError) as exc:
                result = {"config": config.relative_to(ROOT).as_posix(),
                          "variant": "gpu" if gpu else "cpu", "python": "", "image": "",
                          "status": "FAIL", "failed_step": "setup", "failure_category": str(exc),
                          "steps": {}, "imports": empty_imports(), "gpu": {}, "logs": {}}
            finally:
                if plan and not args.keep_images:
                    run(["docker", "image", "rm", "-f", plan.tag],
                        logdir / (slug(plan.config) + "-" + plan.variant + "-cleanup.log"))
                    if not args.keep_build_cache:
                        # Matches previous script: affects Docker's SHARED build cache.
                        run(["docker", "builder", "prune", "-f"],
                            logdir / (slug(plan.config) + "-" + plan.variant + "-cleanup.log"))
            if interrupted:
                break
            results.append(result)
            print("  -> %s %s" % (result["status"], result["failed_step"]), flush=True)
            write_reports(folder, results, meta)
        if interrupted:
            break
    meta["finished"] = now() + (" (interrupted)" if interrupted else "")
    write_reports(folder, results, meta)
    print("Reports: %s" % (folder / "report.md"))
    return 130 if interrupted else 1 if any(r["status"] == "FAIL" for r in results) else 0


if __name__ == "__main__":
    raise SystemExit(main())
