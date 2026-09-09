#!/usr/bin/env python3
"""Generate and validate deterministic DL4MicEverywhere requirements locks.

Normal image builds consume ``requirements.lock.txt`` only.  The human-facing
requirements input is the sibling ``requirements.txt`` for bundled notebook
configurations. ``requirements_url`` remains the immutable provenance/source URL
in configuration.yaml. Custom configurations without a sibling input may still
resolve their declared URL. A lock is generated only when it is missing or stale.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request

LOCK_FORMAT = "1"
UV_VERSION = "0.10.0"
HEADER_PREFIX = "# dl4me-lock-"
GITHUB_RAW_PIN = re.compile(
    r"^https://raw\.githubusercontent\.com/[^/]+/[^/]+/[0-9a-fA-F]{40}/.+$"
)
PACKAGE_RE = re.compile(r"^\s*([A-Za-z0-9][A-Za-z0-9_.-]*)(?:\[[^\]]+\])?\s*(?:[<>=!~@;]|$)")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_text(text: str) -> str:
    return sha256_bytes(text.encode("utf-8"))


def utc_cutoff_for_today() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT23:59:59Z")


def deterministic_cutoff(
    repo_root: Path,
    source: str,
    config_dir: Path | None,
    profile_file: Path | None,
) -> str:
    """Anchor clean repository inputs to their Git history, not runner time.

    For a clean Git checkout, the newest commit timestamp among the local
    requirements input and runtime profile is a stable package-index horizon.
    Dirty working copies, external inputs, and release ZIPs intentionally fall
    back to the current UTC day because there is no committed timestamp that
    describes those inputs.
    """
    if is_url(source) or not (repo_root / ".git").exists() or shutil.which("git") is None:
        return utc_cutoff_for_today()

    source_path = resolve_local_source(source, repo_root, config_dir)
    candidates = [source_path]
    if profile_file is not None:
        candidates.append(profile_file.resolve())

    latest: _dt.datetime | None = None
    for path in candidates:
        try:
            rel = path.resolve().relative_to(repo_root.resolve()).as_posix()
        except ValueError:
            return utc_cutoff_for_today()
        status = subprocess.run(
            ["git", "-C", str(repo_root), "status", "--porcelain", "--", rel],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if status.returncode != 0 or status.stdout.strip():
            return utc_cutoff_for_today()
        try:
            stamp = subprocess.check_output(
                ["git", "-C", str(repo_root), "log", "-1", "--format=%cI", "--", rel],
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
        except subprocess.CalledProcessError:
            return utc_cutoff_for_today()
        if not stamp:
            return utc_cutoff_for_today()
        try:
            value = _dt.datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone(_dt.timezone.utc)
        except ValueError:
            return utc_cutoff_for_today()
        latest = value if latest is None or value > latest else latest

    if latest is None:
        return utc_cutoff_for_today()
    return latest.strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_config_value(config_path: Path, key: str) -> str:
    """Read a scalar under config.dl4miceverywhere without a YAML dependency."""
    lines = config_path.read_text(encoding="utf-8-sig").replace("\r\n", "\n").splitlines()
    in_dl4me = False
    dl4me_indent = None
    pattern = re.compile(rf"^\s*{re.escape(key)}\s*:\s*(.*?)\s*$")
    for raw in lines:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if re.match(r"^\s*dl4miceverywhere\s*:\s*$", raw):
            in_dl4me = True
            dl4me_indent = indent
            continue
        if in_dl4me and dl4me_indent is not None and indent <= dl4me_indent:
            in_dl4me = False
        if in_dl4me:
            match = pattern.match(raw)
            if match:
                value = match.group(1).strip()
                if " #" in value:
                    value = value.split(" #", 1)[0].rstrip()
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                return value
    raise ValueError(f"Missing {key!r} under config.dl4miceverywhere in {config_path}")


def find_repo_root(start: Path) -> Path:
    start = start.resolve()
    for candidate in (start, *start.parents):
        if (candidate / "Linux_launch.sh").is_file() and (candidate / "docker").is_dir():
            return candidate
    raise ValueError(f"Could not locate DL4MicEverywhere repository root from {start}")


def profile_path(repo_root: Path, python_version: str, profile: str | None = None) -> Path | None:
    if profile == "none":
        return None
    if profile and profile != "auto":
        p = Path(profile)
        return p if p.is_absolute() else (repo_root / p)
    if python_version == "3.5":
        name = "python3.5.in"
    elif python_version == "3.6":
        name = "python3.6.in"
    elif python_version == "3.7":
        name = "python3.7.in"
    else:
        major_minor = tuple(int(x) for x in python_version.split(".")[:2])
        if major_minor < (3, 8):
            raise ValueError(f"No runtime lock profile for Python {python_version}")
        name = "python3.8plus.in"
    return repo_root / ".tools" / "lock_profiles" / name


def is_url(value: str) -> bool:
    return value.startswith("http://") or value.startswith("https://")


def resolve_local_source(source: str, repo_root: Path, config_dir: Path | None) -> Path:
    p = Path(source).expanduser()
    if p.is_absolute():
        return p
    candidates = []
    if config_dir is not None:
        candidates.append(config_dir / p)
    candidates.append(repo_root / p)
    for candidate in candidates:
        if candidate.is_file():
            return candidate.resolve()
    return candidates[0].resolve()


def canonical_source(source: str, repo_root: Path, config_dir: Path | None) -> str:
    """Return a stable source locator for lock metadata across machines."""
    if is_url(source):
        return source
    path = resolve_local_source(source, repo_root, config_dir)
    try:
        return path.relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return str(path)


def read_source(source: str, repo_root: Path, config_dir: Path | None) -> tuple[str, bytes]:
    if is_url(source):
        request = urllib.request.Request(source, headers={"User-Agent": "DL4MicEverywhere-locker/1"})
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                data = response.read()
        except Exception as exc:
            raise RuntimeError(f"Could not download requirements input: {source}\n{exc}") from exc
        return source, data
    path = resolve_local_source(source, repo_root, config_dir)
    if not path.is_file():
        raise FileNotFoundError(f"Requirements input does not exist: {path}")
    return str(path), path.read_bytes()


def requirement_name(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#") or stripped.startswith("-"):
        return None
    match = PACKAGE_RE.match(stripped)
    if not match:
        return None
    return re.sub(r"[-_.]+", "-", match.group(1)).lower()


def merge_input_with_runtime(source_text: str, profile_text: str) -> str:
    present = {name for line in source_text.splitlines() if (name := requirement_name(line))}
    defaults = []
    for line in profile_text.splitlines():
        name = requirement_name(line)
        if name is not None and name not in present:
            defaults.append(line.strip())
    merged = source_text.rstrip() + "\n"
    if defaults:
        merged += "\n# DL4MicEverywhere runtime defaults (only when not specified above)\n"
        merged += "\n".join(defaults) + "\n"
    return merged


def parse_header(lock_path: Path) -> tuple[dict[str, str], str]:
    if not lock_path.is_file():
        return {}, ""
    text = lock_path.read_text(encoding="utf-8")
    metadata: dict[str, str] = {}
    body_start = 0
    lines = text.splitlines(keepends=True)
    for index, line in enumerate(lines):
        if line.startswith(HEADER_PREFIX):
            payload = line[len(HEADER_PREFIX):].rstrip("\r\n")
            if ": " in payload:
                key, value = payload.split(": ", 1)
                metadata[key.strip()] = value.strip()
        elif not line.startswith("#") and line.strip():
            body_start = index
            break
        elif not line.strip():
            body_start = index + 1
    body = "".join(lines[body_start:])
    return metadata, body


def expected_metadata(
    source: str,
    repo_root: Path,
    config_dir: Path | None,
    python_version: str,
    profile: str | None,
) -> dict[str, str]:
    ppath = profile_path(repo_root, python_version, profile)
    profile_hash = sha256_bytes(ppath.read_bytes()) if ppath is not None else "none"
    result = {
        "format": LOCK_FORMAT,
        "source": canonical_source(source, repo_root, config_dir),
        "python-version": python_version,
        "runtime-profile": str(ppath.relative_to(repo_root)) if ppath is not None else "none",
        "runtime-profile-sha256": profile_hash,
        "resolver": f"uv=={UV_VERSION}",
    }
    if not is_url(source):
        source_path = resolve_local_source(source, repo_root, config_dir)
        if source_path.is_file():
            result["source-sha256"] = sha256_bytes(source_path.read_bytes())
    return result


def validate_lock(
    lock_path: Path,
    source: str,
    repo_root: Path,
    config_dir: Path | None,
    python_version: str,
    profile: str | None,
) -> tuple[bool, str]:
    metadata, body = parse_header(lock_path)
    if not metadata:
        return False, "missing DL4MicEverywhere lock metadata"
    expected = expected_metadata(source, repo_root, config_dir, python_version, profile)
    for key, value in expected.items():
        if metadata.get(key) != value:
            return False, f"{key} changed"
    if not metadata.get("exclude-newer"):
        return False, "missing exclude-newer cutoff"
    if not metadata.get("body-sha256"):
        return False, "missing lock body hash"
    if sha256_text(body) != metadata["body-sha256"]:
        return False, "lock body was modified"
    # A generated requirements lock should contain hashes. Empty locks are only
    # accepted for truly empty inputs/profiles, which DL4MicEverywhere does not use.
    if body.strip() and "--hash=sha256:" not in body:
        return False, "lock does not contain package hashes"
    return True, "up to date"


def locate_uv(repo_root: Path) -> list[str]:
    uv = shutil.which("uv")
    if uv:
        try:
            version = subprocess.check_output([uv, "--version"], text=True, stderr=subprocess.STDOUT).strip()
        except subprocess.CalledProcessError:
            version = ""
        if version == f"uv {UV_VERSION}":
            return [uv]

    cache = repo_root / ".tools" / ".cache" / "uv" / UV_VERSION
    if os.name == "nt":
        uv_bin = cache / "Scripts" / "uv.exe"
        python_bin = cache / "Scripts" / "python.exe"
    else:
        uv_bin = cache / "bin" / "uv"
        python_bin = cache / "bin" / "python"
    if uv_bin.is_file():
        return [str(uv_bin)]

    cache.parent.mkdir(parents=True, exist_ok=True)
    print(f"Installing pinned lock resolver uv=={UV_VERSION} into {cache} ...")
    subprocess.run([sys.executable, "-m", "venv", str(cache)], check=True)
    subprocess.run(
        [str(python_bin), "-m", "pip", "install", "--disable-pip-version-check", f"uv=={UV_VERSION}"],
        check=True,
    )
    return [str(uv_bin)]


def generate_lock(
    lock_path: Path,
    source: str,
    repo_root: Path,
    config_dir: Path | None,
    python_version: str,
    profile: str | None,
    cutoff: str | None = None,
) -> None:
    if is_url(source) and "raw.githubusercontent.com" in source and not GITHUB_RAW_PIN.match(source):
        raise ValueError(
            "GitHub requirements inputs must contain a full 40-character commit SHA: " + source
        )

    resolved_source, source_bytes = read_source(source, repo_root, config_dir)
    try:
        source_text = source_bytes.decode("utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
    except UnicodeDecodeError as exc:
        raise ValueError(f"Requirements input is not UTF-8 text: {resolved_source}") from exc

    ppath = profile_path(repo_root, python_version, profile)
    profile_text = ppath.read_text(encoding="utf-8") if ppath is not None else ""
    combined = merge_input_with_runtime(source_text, profile_text)

    if cutoff is None:
        cutoff = deterministic_cutoff(repo_root, source, config_dir, ppath)

    uv_cmd = locate_uv(repo_root)
    with tempfile.TemporaryDirectory(prefix="dl4me-lock-") as tmp:
        tmpdir = Path(tmp)
        combined_path = tmpdir / "requirements.txt"
        compiled_path = tmpdir / "requirements.compiled.txt"
        combined_path.write_text(combined, encoding="utf-8", newline="\n")
        cmd = uv_cmd + [
            "pip", "compile", str(combined_path),
            "--python-version", python_version,
            "--python-platform", "linux",
            "--generate-hashes",
            "--no-header",
            "--no-annotate",
            "--exclude-newer", cutoff,
            "--output-file", str(compiled_path),
        ]
        print(f"Resolving {source} for Python {python_version} with uv=={UV_VERSION} ...")
        subprocess.run(cmd, check=True)
        body = compiled_path.read_text(encoding="utf-8").replace("\r\n", "\n")

    metadata = expected_metadata(source, repo_root, config_dir, python_version, profile)
    metadata["source-sha256"] = sha256_bytes(source_bytes)
    metadata["combined-input-sha256"] = sha256_text(combined)
    metadata["exclude-newer"] = cutoff
    metadata["body-sha256"] = sha256_text(body)

    lock_path.parent.mkdir(parents=True, exist_ok=True)
    ordered_keys = [
        "format", "source", "source-sha256", "python-version", "runtime-profile",
        "runtime-profile-sha256", "resolver", "exclude-newer",
        "combined-input-sha256", "body-sha256",
    ]
    header = [
        "# AUTO-GENERATED BY DL4MicEverywhere - DO NOT EDIT",
        "# Edit the requirements input instead; this file is a reproducible build artifact.",
    ]
    for key in ordered_keys:
        header.append(f"{HEADER_PREFIX}{key}: {metadata[key]}")
    text = "\n".join(header) + "\n\n" + body
    lock_path.write_text(text, encoding="utf-8", newline="\n")
    print(f"Wrote lock: {lock_path}")


def default_lock_path(config_path: Path) -> Path:
    return config_path.resolve().parent / "requirements.lock.txt"


def iter_configs(repo_root: Path):
    yield from sorted((repo_root / "notebooks").rglob("configuration.yaml"))


def config_args(config_path: Path) -> tuple[str, str]:
    """Return the build input and Python version for a configuration.

    Bundled configurations keep a committed ``requirements.txt`` beside the YAML.
    The YAML ``requirements_url`` is deliberately a real immutable URL for source
    provenance, while lock generation uses the committed local mirror so ordinary
    builds are not network-dependent. Custom configurations without that sibling
    file fall back to their declared requirements URL.
    """
    declared_url = parse_config_value(config_path, "requirements_url")
    local_input = config_path.resolve().parent / "requirements.txt"
    source = str(local_input) if local_input.is_file() else declared_url
    return (source, parse_config_value(config_path, "python_version"))


def ensure_one(args: argparse.Namespace, force: bool = False) -> int:
    config_path = Path(args.config).resolve() if args.config else None
    anchor = config_path.parent if config_path else Path.cwd()
    repo_root = Path(args.repo_root).resolve() if args.repo_root else find_repo_root(anchor)
    config_dir = config_path.parent if config_path else None

    if config_path:
        cfg_source, cfg_python = config_args(config_path)
    else:
        cfg_source, cfg_python = "", ""
    source = args.source or cfg_source
    python_version = args.python_version or cfg_python
    if not source or not python_version:
        raise ValueError("source and python version are required (directly or via --config)")

    if args.lock:
        lock_path = Path(args.lock).expanduser()
        if not lock_path.is_absolute():
            lock_path = (repo_root / lock_path).resolve()
    elif config_path:
        lock_path = default_lock_path(config_path)
    elif not is_url(source):
        lock_path = resolve_local_source(source, repo_root, config_dir).parent / "requirements.lock.txt"
    else:
        raise ValueError("--lock is required for a URL source when --config is not supplied")

    valid, reason = validate_lock(lock_path, source, repo_root, config_dir, python_version, args.profile)
    if valid and not force:
        if not args.quiet:
            print(f"Lock is up to date: {lock_path}")
        print(lock_path)
        return 0

    if getattr(args, "check_only", False):
        print(f"Stale or missing lock: {lock_path} ({reason})", file=sys.stderr)
        return 1

    if not args.quiet:
        print(f"Lock needs regeneration: {lock_path} ({reason})")
    generate_lock(
        lock_path, source, repo_root, config_dir, python_version, args.profile, args.cutoff
    )
    print(lock_path)
    return 0


def all_configs(args: argparse.Namespace, check_only: bool) -> int:
    repo_root = Path(args.repo_root or ".").resolve()
    failures = 0
    for config in iter_configs(repo_root):
        ns = argparse.Namespace(
            config=str(config), repo_root=str(repo_root), source=None, python_version=None,
            lock=None, profile="auto", cutoff=args.cutoff, quiet=True, check_only=check_only,
        )
        try:
            rc = ensure_one(ns, force=getattr(args, "force", False))
        except Exception as exc:
            rc = 1
            print(f"{config}: {exc}", file=sys.stderr)
        failures += int(rc != 0)
    return 1 if failures else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    def add_one(name: str, help_text: str):
        p = sub.add_parser(name, help=help_text)
        p.add_argument("--config", help="configuration.yaml path")
        p.add_argument("--source", help="requirements input URL/path override")
        p.add_argument("--python-version", help="target Python major.minor override")
        p.add_argument("--lock", help="lockfile path override")
        p.add_argument("--profile", default="auto", help="runtime profile path, auto, or none")
        p.add_argument("--repo-root", help="repository root (normally auto-detected)")
        p.add_argument("--cutoff", help="uv --exclude-newer cutoff for a newly generated lock")
        p.add_argument("--quiet", action="store_true")
        return p

    ensure = add_one("ensure", "Generate the lock only when missing/stale")
    ensure.set_defaults(check_only=False)
    check = add_one("check", "Validate the lock without generating it")
    check.set_defaults(check_only=True)
    generate = add_one("generate", "Force regeneration of one lock")
    generate.set_defaults(check_only=False, force=True)

    for name, text in (("ensure-all", "Ensure every bundled notebook lock"),
                       ("check-all", "Validate every bundled notebook lock")):
        p = sub.add_parser(name, help=text)
        p.add_argument("--repo-root", default=".")
        p.add_argument("--cutoff")
        p.add_argument("--force", action="store_true")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        if args.command == "ensure-all":
            return all_configs(args, check_only=False)
        if args.command == "check-all":
            return all_configs(args, check_only=True)
        return ensure_one(args, force=getattr(args, "force", False))
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"Dependency lock error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
