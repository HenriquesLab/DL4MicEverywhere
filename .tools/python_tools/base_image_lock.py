#!/usr/bin/env python3
"""Maintain immutable Docker base-image references for DL4MicEverywhere.

The notebook configuration remains modular (Ubuntu/CUDA versions). This tool
turns those values into the logical image tags used by the Dockerfiles, resolves
those tags once to immutable registry digests, and stores the result in
``.tools/base_images.lock.yaml``.

Normal builds reuse an existing digest and never refresh it implicitly. Missing
entries may be added automatically. Existing entries change only with
``--refresh`` / ``refresh-all``.

The lock file intentionally uses a tiny, deterministic YAML subset so this tool
has no third-party Python dependency.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Iterable

SCHEMA_VERSION = 1
DEFAULT_LOCK = Path(".tools/base_images.lock.yaml")
CONVERTER_IMAGE = "python:3.9.20-alpine3.19"
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
UBUNTU_RE = re.compile(r"^[0-9]{2}\.[0-9]{2}$")
CUDA_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def find_repo_root(start: Path) -> Path:
    start = start.resolve()
    for candidate in (start, *start.parents):
        if (candidate / "Linux_launch.sh").is_file() and (candidate / "docker").is_dir():
            return candidate
    raise ValueError(f"Could not locate DL4MicEverywhere repository root from {start}")


def parse_config_value(config_path: Path, key: str) -> str:
    """Read a scalar under config.dl4miceverywhere without requiring PyYAML."""
    lines = config_path.read_text(encoding="utf-8-sig").replace("\r\n", "\n").splitlines()
    in_dl4me = False
    dl4me_indent: int | None = None
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


def logical_final_image(config_path: Path, gpu: bool) -> str:
    ubuntu = parse_config_value(config_path, "ubuntu_version")
    if not UBUNTU_RE.fullmatch(ubuntu):
        raise ValueError(f"Unsupported ubuntu_version {ubuntu!r} in {config_path}")
    if not gpu:
        return f"ubuntu:{ubuntu}"

    cuda = parse_config_value(config_path, "cuda_version")
    if not CUDA_RE.fullmatch(cuda):
        raise ValueError(f"Unsupported cuda_version {cuda!r} in {config_path}")
    return f"nvidia/cuda:{cuda}-devel-ubuntu{ubuntu}"


def required_images_for_config(config_path: Path) -> list[str]:
    return [CONVERTER_IMAGE, logical_final_image(config_path, False), logical_final_image(config_path, True)]


def q(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def load_lock(path: Path) -> dict[str, dict[str, object]]:
    """Parse the small YAML subset emitted by ``write_lock``."""
    if not path.exists():
        return {}
    images: dict[str, dict[str, object]] = {}
    current_image: str | None = None
    in_platforms = False
    schema_seen = False
    for line_no, raw in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("schema_version:"):
            try:
                schema = int(stripped.split(":", 1)[1].strip())
            except ValueError as exc:
                raise ValueError(f"Invalid schema_version in {path}:{line_no}") from exc
            if schema != SCHEMA_VERSION:
                raise ValueError(f"Unsupported base-image lock schema {schema}; expected {SCHEMA_VERSION}")
            schema_seen = True
            continue
        if stripped == "images:":
            continue

        indent = len(raw) - len(raw.lstrip(" "))
        if indent == 2 and stripped.endswith(":"):
            key_text = stripped[:-1].strip()
            try:
                image = json.loads(key_text)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid quoted image key in {path}:{line_no}") from exc
            if not isinstance(image, str):
                raise ValueError(f"Image key must be a string in {path}:{line_no}")
            current_image = image
            images[current_image] = {"digest": "", "platforms": {}}
            in_platforms = False
            continue
        if current_image is None:
            raise ValueError(f"Unexpected lock content in {path}:{line_no}: {stripped}")
        if indent == 4 and stripped.startswith("digest:"):
            value_text = stripped.split(":", 1)[1].strip()
            try:
                digest = json.loads(value_text)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid digest value in {path}:{line_no}") from exc
            images[current_image]["digest"] = digest
            in_platforms = False
            continue
        if indent == 4 and stripped == "platforms:":
            in_platforms = True
            continue
        if indent == 6 and in_platforms and ":" in stripped:
            key_text, value_text = stripped.split(":", 1)
            try:
                platform = json.loads(key_text.strip())
                digest = json.loads(value_text.strip())
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid platform mapping in {path}:{line_no}") from exc
            platforms = images[current_image]["platforms"]
            assert isinstance(platforms, dict)
            platforms[platform] = digest
            continue
        raise ValueError(f"Unexpected lock content in {path}:{line_no}: {stripped}")

    if path.exists() and not schema_seen:
        raise ValueError(f"Missing schema_version in {path}")
    validate_entries(images, path)
    return images


def validate_entries(images: dict[str, dict[str, object]], path: Path | None = None) -> None:
    where = f" in {path}" if path else ""
    for image, entry in images.items():
        digest = entry.get("digest")
        if not isinstance(digest, str) or not DIGEST_RE.fullmatch(digest):
            raise ValueError(f"Invalid digest for {image}{where}: {digest!r}")
        platforms = entry.get("platforms", {})
        if not isinstance(platforms, dict):
            raise ValueError(f"Invalid platforms mapping for {image}{where}")
        for platform, platform_digest in platforms.items():
            if not isinstance(platform, str) or not platform.startswith("linux/"):
                raise ValueError(f"Invalid platform key for {image}{where}: {platform!r}")
            if not isinstance(platform_digest, str) or not DIGEST_RE.fullmatch(platform_digest):
                raise ValueError(f"Invalid platform digest for {image} {platform}{where}: {platform_digest!r}")


def write_lock(path: Path, images: dict[str, dict[str, object]]) -> None:
    validate_entries(images)
    lines = [
        "# AUTO-GENERATED BY .tools/python_tools/base_image_lock.py",
        "# Existing digests are immutable pins. Use refresh-all intentionally to update them.",
        f"schema_version: {SCHEMA_VERSION}",
        "images:",
    ]
    for image in sorted(images):
        entry = images[image]
        lines.append(f"  {q(image)}:")
        lines.append(f"    digest: {q(str(entry['digest']))}")
        lines.append("    platforms:")
        platforms = entry.get("platforms", {})
        assert isinstance(platforms, dict)
        for platform in sorted(platforms):
            lines.append(f"      {q(platform)}: {q(str(platforms[platform]))}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def _docker_command() -> str:
    docker = shutil.which("docker")
    if not docker:
        raise RuntimeError("Docker is required to resolve missing base-image digests.")
    probe = subprocess.run(
        [docker, "buildx", "version"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if probe.returncode != 0:
        raise RuntimeError("Docker Buildx is required to resolve base-image digests (docker buildx version failed).")
    return docker


def inspect_image(image: str) -> dict[str, object]:
    """Resolve an image tag to an immutable index/manifest digest via Buildx."""
    docker = _docker_command()
    cmd = [docker, "buildx", "imagetools", "inspect", image, "--format", "{{json .Manifest}}"]
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if proc.returncode != 0:
        raise RuntimeError(
            f"Could not resolve base image {image!r}.\n"
            f"Command: {' '.join(cmd)}\n{proc.stderr.strip()}"
        )
    try:
        manifest = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Buildx returned invalid manifest JSON for {image!r}: {proc.stdout[:500]!r}") from exc

    digest = manifest.get("digest") or manifest.get("Digest")
    if not isinstance(digest, str) or not DIGEST_RE.fullmatch(digest):
        # Compatibility fallback for older Buildx formatting implementations.
        plain = subprocess.run(
            [docker, "buildx", "imagetools", "inspect", image],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        match = re.search(r"^Digest:\s*(sha256:[0-9a-f]{64})\s*$", plain.stdout, re.MULTILINE)
        if not match:
            raise RuntimeError(f"Could not determine immutable digest for {image!r} from Docker Buildx output.")
        digest = match.group(1)

    platforms: dict[str, str] = {}
    manifests = manifest.get("manifests") or manifest.get("Manifests") or []
    if isinstance(manifests, list):
        for item in manifests:
            if not isinstance(item, dict):
                continue
            pdigest = item.get("digest") or item.get("Digest")
            platform = item.get("platform") or item.get("Platform") or {}
            if not isinstance(pdigest, str) or not DIGEST_RE.fullmatch(pdigest) or not isinstance(platform, dict):
                continue
            os_name = platform.get("os") or platform.get("OS")
            arch = platform.get("architecture") or platform.get("Architecture")
            variant = platform.get("variant") or platform.get("Variant")
            if os_name != "linux" or not arch or arch == "unknown":
                continue
            key = f"{os_name}/{arch}"
            if arch == "arm" and variant:
                key += f"/{variant}"
            platforms[key] = pdigest

    return {"digest": digest, "platforms": platforms}


def lock_path(repo_root: Path, value: str | None) -> Path:
    if value:
        path = Path(value)
        return path if path.is_absolute() else (repo_root / path)
    return repo_root / DEFAULT_LOCK


def ensure_images(path: Path, wanted: Iterable[str], refresh: bool = False) -> tuple[dict[str, dict[str, object]], bool]:
    images = load_lock(path) if path.exists() else {}
    changed = False
    for image in sorted(set(wanted)):
        if image in images and not refresh:
            continue
        action = "Refreshing" if image in images else "Locking"
        print(f"{action} base image: {image}", file=sys.stderr)
        images[image] = inspect_image(image)
        changed = True
    if changed or not path.exists():
        write_lock(path, images)
    return images, changed


def pinned_ref(images: dict[str, dict[str, object]], image: str) -> str:
    if image not in images:
        raise KeyError(f"Base image {image!r} is not present in the lock file")
    digest = images[image]["digest"]
    assert isinstance(digest, str)
    return f"{image}@{digest}"


def configs_under(repo_root: Path) -> list[Path]:
    return sorted((repo_root / "notebooks").rglob("configuration.yaml"))


def all_required_images(repo_root: Path) -> list[str]:
    wanted = {CONVERTER_IMAGE}
    for config in configs_under(repo_root):
        wanted.update(required_images_for_config(config))
    return sorted(wanted)


def required_platforms(image: str) -> set[str]:
    # CPU and converter stages are built for both platforms in CI. GPU builds are
    # currently published only for amd64, but the index may contain more.
    if image.startswith("nvidia/cuda:"):
        return {"linux/amd64"}
    return {"linux/amd64", "linux/arm64"}


def check_images(images: dict[str, dict[str, object]], wanted: Iterable[str], require_platform_metadata: bool = False) -> list[str]:
    errors: list[str] = []
    for image in sorted(set(wanted)):
        if image not in images:
            errors.append(f"Missing base-image lock entry: {image}")
            continue
        entry = images[image]
        digest = entry.get("digest")
        if not isinstance(digest, str) or not DIGEST_RE.fullmatch(digest):
            errors.append(f"Invalid digest for {image}: {digest!r}")
            continue
        if require_platform_metadata:
            platforms = entry.get("platforms", {})
            if not isinstance(platforms, dict):
                errors.append(f"Invalid platforms mapping for {image}")
                continue
            missing = required_platforms(image) - set(platforms)
            if missing:
                errors.append(f"{image} does not advertise required platform(s): {', '.join(sorted(missing))}")
    return errors


def cmd_ensure_for_build(args: argparse.Namespace, repo_root: Path, path: Path) -> int:
    config = Path(args.config)
    if not config.is_absolute():
        config = repo_root / config
    final = logical_final_image(config, bool(args.gpu))
    images, _ = ensure_images(path, [CONVERTER_IMAGE, final], refresh=False)
    converter_ref = pinned_ref(images, CONVERTER_IMAGE)
    final_ref = pinned_ref(images, final)
    if args.shell:
        print(f"CONVERTER_BASE_IMAGE={q(converter_ref)}")
        print(f"FINAL_BASE_IMAGE={q(final_ref)}")
    else:
        print(json.dumps({"converter_base_image": converter_ref, "final_base_image": final_ref}, sort_keys=True))
    return 0


def cmd_check_for_build(args: argparse.Namespace, repo_root: Path, path: Path) -> int:
    config = Path(args.config)
    if not config.is_absolute():
        config = repo_root / config
    final = logical_final_image(config, bool(args.gpu))
    try:
        images = load_lock(path)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1
    errors = check_images(images, [CONVERTER_IMAGE, final], require_platform_metadata=args.require_platform_metadata)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    if args.shell:
        print(f"CONVERTER_BASE_IMAGE={q(pinned_ref(images, CONVERTER_IMAGE))}")
        print(f"FINAL_BASE_IMAGE={q(pinned_ref(images, final))}")
    return 0



def cmd_ensure_config(args: argparse.Namespace, repo_root: Path, path: Path) -> int:
    config = Path(args.config)
    if not config.is_absolute():
        config = repo_root / config
    cpu = logical_final_image(config, False)
    gpu = logical_final_image(config, True)
    images, _ = ensure_images(path, [CONVERTER_IMAGE, cpu, gpu], refresh=False)
    values = {
        "CONVERTER_BASE_IMAGE": pinned_ref(images, CONVERTER_IMAGE),
        "CPU_BASE_IMAGE": pinned_ref(images, cpu),
        "GPU_BASE_IMAGE": pinned_ref(images, gpu),
    }
    if args.shell:
        for key, value in values.items():
            print(f"{key}={q(value)}")
    else:
        print(json.dumps({key.lower(): value for key, value in values.items()}, sort_keys=True))
    return 0


def cmd_check_config(args: argparse.Namespace, repo_root: Path, path: Path) -> int:
    config = Path(args.config)
    if not config.is_absolute():
        config = repo_root / config
    cpu = logical_final_image(config, False)
    gpu = logical_final_image(config, True)
    try:
        images = load_lock(path)
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1
    wanted = [CONVERTER_IMAGE, cpu, gpu]
    errors = check_images(images, wanted, require_platform_metadata=args.require_platform_metadata)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    if args.shell:
        print(f"CONVERTER_BASE_IMAGE={q(pinned_ref(images, CONVERTER_IMAGE))}")
        print(f"CPU_BASE_IMAGE={q(pinned_ref(images, cpu))}")
        print(f"GPU_BASE_IMAGE={q(pinned_ref(images, gpu))}")
    return 0

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=None, help="Repository root (auto-detected by default)")
    parser.add_argument("--lock", default=None, help=f"Lock path (default: {DEFAULT_LOCK})")
    sub = parser.add_subparsers(dest="command", required=True)

    ensure_build = sub.add_parser("ensure-for-build", help="Add missing pins needed for one build and print pinned refs")
    ensure_build.add_argument("--config", required=True)
    ensure_build.add_argument("--gpu", type=int, choices=(0, 1), required=True)
    ensure_build.add_argument("--shell", action="store_true", help="Print shell assignments")

    check_build = sub.add_parser("check-for-build", help="Validate committed pins needed for one build")
    check_build.add_argument("--config", required=True)
    check_build.add_argument("--gpu", type=int, choices=(0, 1), required=True)
    check_build.add_argument("--shell", action="store_true")
    check_build.add_argument("--require-platform-metadata", action="store_true")

    ensure_config = sub.add_parser("ensure-config", help="Add missing converter, CPU and GPU pins for one configuration")
    ensure_config.add_argument("--config", required=True)
    ensure_config.add_argument("--shell", action="store_true")

    check_config = sub.add_parser("check-config", help="Validate converter, CPU and GPU pins for one configuration")
    check_config.add_argument("--config", required=True)
    check_config.add_argument("--shell", action="store_true")
    check_config.add_argument("--require-platform-metadata", action="store_true")

    sub.add_parser("ensure-all", help="Resolve only base images that are missing from the lock")
    sub.add_parser("refresh-all", help="Intentionally re-resolve every currently required base image")
    check_all = sub.add_parser("check-all", help="Validate that every bundled configuration is fully base-image locked")
    check_all.add_argument("--require-platform-metadata", action="store_true")
    list_cmd = sub.add_parser("list", help="List logical base images required by bundled configurations")
    list_cmd.add_argument("--pinned", action="store_true", help="Print pinned references when available")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    repo_root = Path(args.repo_root).resolve() if args.repo_root else find_repo_root(Path.cwd())
    path = lock_path(repo_root, args.lock)

    try:
        if args.command == "ensure-for-build":
            return cmd_ensure_for_build(args, repo_root, path)
        if args.command == "check-for-build":
            return cmd_check_for_build(args, repo_root, path)
        if args.command == "ensure-config":
            return cmd_ensure_config(args, repo_root, path)
        if args.command == "check-config":
            return cmd_check_config(args, repo_root, path)
        if args.command in {"ensure-all", "refresh-all"}:
            ensure_images(path, all_required_images(repo_root), refresh=args.command == "refresh-all")
            return 0
        if args.command == "check-all":
            images = load_lock(path)
            errors = check_images(images, all_required_images(repo_root), require_platform_metadata=args.require_platform_metadata)
            if errors:
                print("\n".join(errors), file=sys.stderr)
                return 1
            print(f"Base-image lock is complete: {len(all_required_images(repo_root))} logical images.")
            return 0
        if args.command == "list":
            wanted = all_required_images(repo_root)
            images = load_lock(path) if path.exists() else {}
            for image in wanted:
                if args.pinned and image in images:
                    print(pinned_ref(images, image))
                else:
                    print(image)
            return 0
    except (ValueError, RuntimeError, FileNotFoundError, KeyError) as exc:
        print(f"base-image lock error: {exc}", file=sys.stderr)
        return 1
    parser.error(f"Unhandled command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
