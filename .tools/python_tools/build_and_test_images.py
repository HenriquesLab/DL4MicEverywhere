#!/usr/bin/env python3
"""Build every notebook image locally, check it, and write a report.

For each ``notebooks/**/configuration.yaml`` this script:

1. resolves the dependency lock and the pinned base images exactly like
   ``Linux_launch.sh`` does when it builds an image;
2. builds the Docker image with the same Dockerfile and build arguments;
3. runs ``post_build_test.sh`` (Python, ``pip check``, Jupyter, GPU when built
   for GPU);
4. imports, inside the image, every module the converted notebook imports, so
   failures such as ``No module named 'pkg_resources'`` are found before a user
   runs the notebook;
5. removes the image (and, by default, the Docker build cache) so a long run
   does not fill the disk.

Results are written after every notebook to ``report.md`` and ``report.json``
in the output folder, with one log file per step. Run it where DL4MicEverywhere
itself runs (Linux, WSL, or macOS with Docker available):

    python3 .tools/python_tools/build_and_test_images.py
    python3 .tools/python_tools/build_and_test_images.py --only StarDist --only CARE_2D
    python3 .tools/python_tools/build_and_test_images.py --variant gpu
    python3 .tools/python_tools/build_and_test_images.py --dry-run
"""

from __future__ import annotations

import argparse
import datetime as _dt
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_IMAGE_REPOSITORY = "dl4me-image-test"
IMPORT_REPORT_MARKER = "DL4ME_IMPORT_REPORT:"

_lock_spec = importlib.util.spec_from_file_location(
    "requirements_lock", Path(__file__).resolve().parent / "requirements_lock.py"
)
requirements_lock = importlib.util.module_from_spec(_lock_spec)
assert _lock_spec.loader is not None
_lock_spec.loader.exec_module(requirements_lock)

# Runs inside the image with the image's own Python (as old as 3.5 for legacy
# notebooks), so it must avoid f-strings and newer syntax. It collects the
# import statements of every code cell of the converted notebook and executes
# each one. Imports inside `try:` blocks are optional fallbacks: a failure there
# is reported as a warning, not an error. Some notebooks deliberately keep an
# install section (`!git clone ...`, `!pip install git+...`, `!wget code.zip`) that
# provides modules only when the user runs it; when such commands remain, failing
# imports are reported as "installed at run time" warnings, together with the commands.
IMPORT_CHECK_CODE = r'''
import ast
import json
import os
import re
import sys

# Jupyter plots with its inline backend; without this, old matplotlib versions
# pick TkAgg in a plain Python process and `import pyplot` fails on tkinter.
os.environ.setdefault("MPLBACKEND", "Agg")

MARKER = "DL4ME_IMPORT_REPORT:"
INSTALL_COMMAND = re.compile(
    r"(pip3?|conda|mamba)\s+install|git\s+clone|setup\.py\s+(install|develop)|\b(wget|curl)\s")
install_commands = []


def code_cells(notebook_path):
    with open(notebook_path, encoding="utf-8") as handle:
        notebook = json.load(handle)
    for cell in notebook.get("cells", []):
        if cell.get("cell_type") != "code":
            continue
        source = cell.get("source", "")
        if isinstance(source, list):
            source = "".join(source)
        # Shell commands and IPython magics are not Python syntax.
        lines = []
        for line in source.splitlines():
            if line.lstrip().startswith(("!", "%")):
                if INSTALL_COMMAND.search(line) and "uninstall" not in line:
                    install_commands.append(line.strip())
            else:
                lines.append(line)
        yield "\n".join(lines)


def statement_for(node):
    if isinstance(node, ast.Import):
        return ["import %s" % alias.name for alias in node.names]
    if node.level:
        return []
    names = ", ".join(alias.name for alias in node.names)
    return ["from %s import %s" % (node.module, names)]


def collect(nodes, optional, found):
    for node in nodes:
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            for statement in statement_for(node):
                found.append((statement, optional))
            continue
        if node.__class__.__name__ in ("Try", "TryExcept", "TryFinally", "TryStar"):
            collect(getattr(node, "body", []), True, found)
            for handler in getattr(node, "handlers", []):
                collect(handler.body, True, found)
            collect(getattr(node, "orelse", []), optional, found)
            collect(getattr(node, "finalbody", []), optional, found)
            continue
        for field in ("body", "orelse", "finalbody"):
            collect(getattr(node, field, []) or [], optional, found)


IMPORT_LINE = re.compile(r"^\s*((?:import|from)\s+[A-Za-z_][\w.]*.*)$")

found = []
for code in code_cells(sys.argv[1]):
    try:
        collect(ast.parse(code).body, False, found)
    except SyntaxError:
        # Cells with unusual IPython syntax: fall back to plain import lines.
        for line in code.splitlines():
            match = IMPORT_LINE.match(line)
            if match and (" import " in match.group(1) or match.group(1).startswith("import ")):
                found.append((match.group(1).split("#")[0].strip(), False))

results = []
seen = set()
for statement, optional in found:
    if statement in seen:
        continue
    seen.add(statement)
    entry = {"statement": statement, "optional": optional, "runtime": False, "ok": True, "error": ""}
    try:
        exec(statement, {})
    except BaseException as exc:
        entry["ok"] = False
        entry["error"] = "%s: %s" % (exc.__class__.__name__, exc)
        # Only "the imported package itself is absent" can be explained by the
        # notebook's own install commands. A package that is present but fails
        # on one of its dependencies (stardist -> pkg_resources) is a real bug.
        # google.colab only exists on Google Colab, so it is never "installed".
        module = statement.split()[1]
        missing = (getattr(exc, "name", None) or "").split(".")[0]
        entry["runtime"] = (bool(install_commands) and not optional
                            and isinstance(exc, ImportError) and missing == module.split(".")[0]
                            and not module.startswith("google.colab"))
    results.append(entry)

# On its own line: imported packages may print progress bars without a newline.
sys.stdout.write("\n" + MARKER + json.dumps({"imports": results, "install_commands": install_commands}) + "\n")
sys.stdout.flush()
required_failures = [r for r in results if not r["ok"] and not r["optional"] and not r["runtime"]]
sys.exit(1 if required_failures else 0)
'''


def now() -> str:
    return _dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def config_value(config: Path, key: str, default: str | None = None) -> str:
    try:
        return requirements_lock.parse_config_value(config, key)
    except ValueError:
        if default is None:
            raise
        return default


def is_legacy_python(python_version: str) -> bool:
    return python_version in ("3.5", "3.6")


def select_dockerfile(gpu: bool, python_version: str) -> str:
    legacy = is_legacy_python(python_version)
    if gpu:
        return "docker/Dockerfile.gpu.legacy" if legacy else "docker/Dockerfile.gpu.modern"
    return "docker/Dockerfile.legacy" if legacy else "docker/Dockerfile.modern"


def notebook_slug(config: Path) -> str:
    return re.sub(r"[^a-z0-9_.-]+", "-", config.parent.name.lower()).strip("-.") or "notebook"


def discover_configs(repo_root: Path, only: list[str]) -> list[Path]:
    configs = sorted((repo_root / "notebooks").rglob("configuration.yaml"))
    if only:
        wanted = [value.lower() for value in only]
        configs = [c for c in configs if any(w in str(c.relative_to(repo_root)).lower() for w in wanted)]
    return configs


def docker_platform() -> str:
    """Architecture Docker builds for, as used for the requirement locks."""
    result = subprocess.run(
        ["docker", "info", "--format", "{{.Architecture}}"],
        text=True, capture_output=True, check=False,
    )
    return "arm64" if result.stdout.strip() in ("aarch64", "arm64") else "amd64"


def run_logged(command: list[str], log_path: Path, timeout: int | None = None) -> tuple[int, float]:
    """Run a command, appending its output to a log file. Returns (status, seconds)."""
    start = time.monotonic()
    with log_path.open("a", encoding="utf-8") as log:
        log.write("$ " + " ".join(command) + "\n")
        log.flush()
        try:
            status = subprocess.run(
                command, cwd=REPO_ROOT, stdout=log, stderr=subprocess.STDOUT,
                timeout=timeout, check=False,
            ).returncode
        except subprocess.TimeoutExpired:
            log.write(f"\nTIMEOUT after {timeout} seconds\n")
            status = 124
    return status, time.monotonic() - start


class Plan:
    """Everything needed to build and test one notebook image."""

    def __init__(self, config: Path, gpu: bool, platform: str):
        self.config = config
        self.gpu = gpu
        self.platform = platform
        self.relative_config = config.relative_to(REPO_ROOT).as_posix()
        self.python_version = config_value(config, "python_version")
        self.ubuntu_version = config_value(config, "ubuntu_version")
        self.cuda_version = config_value(config, "cuda_version", "")
        self.cudnn_version = config_value(config, "cudnn_version", "")
        self.notebook_url = config_value(config, "notebook_url")
        self.requirements_url = config_value(config, "requirements_url", "")
        self.sections_to_remove = config_value(config, "sections_to_remove", "")
        self.notebook_name = self.notebook_url.rstrip("/").rsplit("/", 1)[-1]
        self.dockerfile = select_dockerfile(gpu, self.python_version)
        self.variant = "gpu" if gpu else "cpu"
        self.tag = f"{TEST_IMAGE_REPOSITORY}:{notebook_slug(config)}-{self.variant}"
        lock = requirements_lock.default_lock_path(config, platform)
        self.lock_relative = lock.relative_to(REPO_ROOT.resolve()).as_posix()

    def build_command(self, converter_base: str, final_base: str) -> list[str]:
        build_args = {
            "CONVERTER_BASE_IMAGE": converter_base,
            "FINAL_BASE_IMAGE": final_base,
            "UBUNTU_VERSION": self.ubuntu_version,
            "CUDA_VERSION": self.cuda_version,
            "CUDNN_VERSION": self.cudnn_version,
            "GPU_FLAG": "1" if self.gpu else "0",
            "PYTHON_VERSION": self.python_version,
            "PATH_TO_NOTEBOOK": self.notebook_url,
            "PATH_TO_REQUIREMENTS": self.requirements_url,
            "PATH_TO_REQUIREMENTS_LOCK": self.lock_relative,
            "NOTEBOOK_NAME": self.notebook_name,
            "SECTIONS_TO_REMOVE": self.sections_to_remove,
        }
        command = [
            "docker", "build", "--file", self.dockerfile, "-t", self.tag,
            "--label", "org.dl4miceverywhere.managed=true",
            "--label", "org.dl4miceverywhere.image-test=true",
        ]
        for key, value in build_args.items():
            command += ["--build-arg", f"{key}={value}"]
        return command + ["."]

    def import_command(self) -> list[str]:
        command = ["docker", "run", "--rm"]
        if self.gpu:
            command += ["--gpus", "all"]
        return command + [self.tag, "python", "-c", IMPORT_CHECK_CODE, f"/home/{self.notebook_name}"]


def parse_import_report(log_text: str) -> dict | None:
    for line in reversed(log_text.splitlines()):
        position = line.find(IMPORT_REPORT_MARKER)
        if position >= 0:
            try:
                return json.loads(line[position + len(IMPORT_REPORT_MARKER):])
            except ValueError:
                return None
    return None


def empty_imports() -> dict:
    return {"total": 0, "failed": [], "optional_failed": [], "runtime_failed": [], "install_commands": []}


def test_one(plan: Plan, log_dir: Path, args: argparse.Namespace) -> dict:
    stem = f"{notebook_slug(plan.config)}-{plan.variant}"
    logs = {name: log_dir / f"{stem}-{name}.log" for name in ("prepare", "build", "smoke", "imports")}
    result = {
        "config": plan.relative_config,
        "variant": plan.variant,
        "python": plan.python_version,
        "image": plan.tag,
        "started": now(),
        "status": "FAIL",
        "failed_step": "",
        "steps": {},
        "imports": empty_imports(),
        "image_size_gb": None,
        "logs": {name: path.relative_to(log_dir.parent).as_posix() for name, path in logs.items()},
    }

    def step(name: str, status: int, seconds: float) -> bool:
        result["steps"][name] = {"ok": status == 0, "seconds": round(seconds, 1)}
        if status != 0 and not result["failed_step"]:
            result["failed_step"] = name
        return status == 0

    # 1. Dependency lock and pinned base images, as Linux_launch.sh does.
    python = sys.executable
    status, seconds = run_logged(
        [python, ".tools/python_tools/requirements_lock.py", "ensure", "--config", plan.relative_config,
         "--platform", plan.platform, "--repo-root", "."], logs["prepare"])
    if status == 0:
        more_status, more_seconds = run_logged(
            [python, ".tools/python_tools/requirements_lock.py", "ensure",
             "--source", "docker/converter-requirements.txt", "--python-version", "3.9",
             "--lock", "docker/converter-requirements.lock.txt", "--profile", "none", "--repo-root", "."],
            logs["prepare"])
        status, seconds = more_status, seconds + more_seconds
    base_images = {}
    if status == 0:
        start = time.monotonic()
        pinned = subprocess.run(
            [python, ".tools/python_tools/base_image_lock.py", "--repo-root", ".", "ensure-for-build",
             "--config", plan.relative_config, "--gpu", "1" if plan.gpu else "0"],
            cwd=REPO_ROOT, text=True, capture_output=True, check=False,
        )
        with logs["prepare"].open("a", encoding="utf-8") as log:
            log.write(pinned.stdout + pinned.stderr)
        status, seconds = pinned.returncode, seconds + time.monotonic() - start
        if status == 0:
            base_images = json.loads(pinned.stdout.strip().splitlines()[-1])
    if not step("prepare", status, seconds):
        return result

    # 2. Build.
    status, seconds = run_logged(
        plan.build_command(base_images["converter_base_image"], base_images["final_base_image"]),
        logs["build"], timeout=args.build_timeout * 60)
    if not step("build", status, seconds):
        return result

    size = subprocess.run(["docker", "image", "inspect", "--format", "{{.Size}}", plan.tag],
                          text=True, capture_output=True, check=False).stdout.strip()
    if size.isdigit():
        result["image_size_gb"] = round(int(size) / 1e9, 2)

    # 3. The launcher's post-build smoke test (strict pip check: built in this run).
    status, seconds = run_logged(
        ["bash", ".tools/bash_tools/post_build_test.sh", plan.tag, "1" if plan.gpu else "0", "1"],
        logs["smoke"], timeout=args.test_timeout * 60)
    step("smoke", status, seconds)

    # 4. Every import of the converted notebook, inside the image.
    status, seconds = run_logged(plan.import_command(), logs["imports"], timeout=args.test_timeout * 60)
    report = parse_import_report(logs["imports"].read_text(encoding="utf-8", errors="replace"))
    if report is None:
        status = status or 1
    else:
        entries = report["imports"]
        result["imports"] = {
            "total": len(entries),
            "failed": [r for r in entries if not r["ok"] and not r["optional"] and not r.get("runtime")],
            "optional_failed": [r for r in entries if not r["ok"] and r["optional"]],
            "runtime_failed": [r for r in entries if not r["ok"] and r.get("runtime")],
            "install_commands": report.get("install_commands", []),
        }
    step("imports", status, seconds)

    if not result["failed_step"]:
        warnings = result["imports"]["optional_failed"] or result["imports"]["runtime_failed"]
        result["status"] = "WARN" if warnings else "PASS"
    return result


def cleanup(plan: Plan, args: argparse.Namespace, log_path: Path) -> None:
    if args.keep_images:
        return
    run_logged(["docker", "image", "rm", "-f", plan.tag], log_path)
    if not args.keep_build_cache:
        # The build cache is shared by the whole Docker daemon and grows by
        # several GB per notebook; this run was asked to keep the disk free.
        run_logged(["docker", "builder", "prune", "-f"], log_path)


def write_reports(output_dir: Path, results: list[dict], meta: dict) -> None:
    (output_dir / "report.json").write_text(
        json.dumps({"meta": meta, "results": results}, indent=2), encoding="utf-8")

    counts = {status: sum(r["status"] == status for r in results) for status in ("PASS", "WARN", "FAIL")}
    lines = [
        "# DL4MicEverywhere image test report",
        "",
        f"- Started: {meta['started']}",
        f"- Finished: {meta.get('finished', 'running...')}",
        f"- Docker platform: linux/{meta['platform']}",
        f"- Variant(s): {', '.join(meta['variants'])}",
        f"- Notebooks planned: {meta['planned']}",
        f"- Result so far: {counts['PASS']} PASS, {counts['WARN']} WARN, {counts['FAIL']} FAIL",
        "",
        "PASS = built, smoke test and all notebook imports OK. "
        "WARN = only optional imports (inside `try:` blocks) failed, or imports failed in a notebook "
        "that still has its own install commands (`!pip install`, `!git clone`, `!wget`), which provide those "
        "modules when the user runs them; check that the listed commands really install them. "
        "FAIL = see the failed step and its log.",
        "",
        "| Notebook | Variant | Python | Status | Failed step | Build (min) | Image (GB) | Imports | Failed imports | Logs |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for r in results:
        build = r["steps"].get("build", {})
        build_minutes = f"{build['seconds'] / 60:.1f}" if build else ""
        imports = {**empty_imports(), **r["imports"]}
        failed = "; ".join(f"`{f['statement']}`: {f['error']}" for f in imports["failed"])
        optional = "; ".join(f"`{f['statement']}` (optional)" for f in imports["optional_failed"])
        runtime = "; ".join(f"`{f['statement']}` (installed at run time?)" for f in imports["runtime_failed"])
        if runtime:
            runtime += " — notebook install commands: " + "; ".join(
                f"`{c}`" for c in imports["install_commands"][:5])
        failed_text = "; ".join(t for t in (failed, runtime, optional) if t).replace("|", "\\|")
        ok_imports = (imports["total"] - len(imports["failed"]) - len(imports["optional_failed"])
                      - len(imports["runtime_failed"]))
        import_text = f"{ok_imports}/{imports['total']}" if "imports" in r["steps"] else ""
        logs = " ".join(f"[{name}]({path})" for name, path in r["logs"].items()
                        if (output_dir / path).exists())
        lines.append(
            f"| {Path(r['config']).parent.name} | {r['variant']} | {r['python']} | {r['status']} | "
            f"{r['failed_step']} | {build_minutes} | {r['image_size_gb'] or ''} | {import_text} | "
            f"{failed_text} | {logs} |"
        )
    (output_dir / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--only", action="append", default=[],
                        help="Test only configurations whose path contains this text (repeatable)")
    parser.add_argument("--variant", choices=("cpu", "gpu", "both"), default="cpu",
                        help="Image variant(s) to build (GPU needs an NVIDIA GPU usable by Docker)")
    parser.add_argument("--output-dir", default="image_test_reports",
                        help="Folder for the timestamped report folders (default: image_test_reports)")
    parser.add_argument("--keep-images", action="store_true", help="Do not remove the tested images")
    parser.add_argument("--keep-build-cache", action="store_true",
                        help="Do not run 'docker builder prune' after each image")
    parser.add_argument("--build-timeout", type=int, default=120, help="Minutes allowed per build (default 120)")
    parser.add_argument("--test-timeout", type=int, default=30, help="Minutes allowed per test step (default 30)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Only list what would be built, with the Dockerfile and image tag")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    configs = discover_configs(REPO_ROOT, args.only)
    if not configs:
        print("No configuration.yaml matched.", file=sys.stderr)
        return 1
    variants = {"cpu": [False], "gpu": [True], "both": [False, True]}[args.variant]

    if args.dry_run:
        for config in configs:
            for gpu in variants:
                plan = Plan(config, gpu, "amd64")
                print(f"{plan.relative_config}\n    {plan.dockerfile} -> {plan.tag} (Python {plan.python_version})")
        print(f"\n{len(configs) * len(variants)} image(s) would be built and tested.")
        return 0

    for tool in ("docker", "bash"):
        if shutil.which(tool) is None:
            print(f"'{tool}' is required. Run this script where DL4MicEverywhere runs (Linux, WSL or macOS).",
                  file=sys.stderr)
            return 1
    if subprocess.run(["docker", "info"], capture_output=True, check=False).returncode != 0:
        print("Docker is not running or not accessible ('docker info' failed).", file=sys.stderr)
        return 1

    platform = docker_platform()
    stamp = _dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = (REPO_ROOT / args.output_dir / stamp) if not Path(args.output_dir).is_absolute() \
        else Path(args.output_dir) / stamp
    log_dir = output_dir / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    meta = {"started": now(), "platform": platform, "variants": [("gpu" if g else "cpu") for g in variants],
            "planned": len(configs) * len(variants)}

    print(f"Testing {meta['planned']} image(s) on linux/{platform}. Report: {output_dir / 'report.md'}")
    if not args.keep_images and not args.keep_build_cache:
        print("After each image, the image is removed and 'docker builder prune -f' clears the Docker build cache.")

    results: list[dict] = []
    interrupted = False
    for index, config in enumerate(configs, 1):
        for gpu in variants:
            try:
                plan = Plan(config, gpu, platform)
            except (ValueError, OSError) as exc:
                results.append({"config": config.relative_to(REPO_ROOT).as_posix(), "variant": "gpu" if gpu else "cpu",
                                "python": "", "image": "", "status": "FAIL", "failed_step": f"config: {exc}",
                                "steps": {}, "imports": empty_imports(),
                                "image_size_gb": None, "logs": {}})
                write_reports(output_dir, results, meta)
                continue
            print(f"[{index}/{len(configs)}] {plan.relative_config} ({plan.variant}) ...", flush=True)
            try:
                result = test_one(plan, log_dir, args)
            except KeyboardInterrupt:
                interrupted = True
                result = {"config": plan.relative_config, "variant": plan.variant, "python": plan.python_version,
                          "image": plan.tag, "status": "FAIL", "failed_step": "interrupted", "steps": {},
                          "imports": empty_imports(), "image_size_gb": None,
                          "logs": {}}
            finally:
                cleanup(plan, args, log_dir / f"{notebook_slug(config)}-{plan.variant}-cleanup.log")
            results.append(result)
            print(f"    {result['status']}" + (f" (failed step: {result['failed_step']})" if result["failed_step"] else ""),
                  flush=True)
            write_reports(output_dir, results, meta)
            if interrupted:
                break
        if interrupted:
            break

    meta["finished"] = now() + (" (interrupted)" if interrupted else "")
    write_reports(output_dir, results, meta)
    print(f"\nReport: {output_dir / 'report.md'}")
    if interrupted:
        return 130
    return 0 if all(r["status"] != "FAIL" for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
