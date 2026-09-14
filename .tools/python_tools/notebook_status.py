#!/usr/bin/env python3
"""Maintain the automatically generated notebook Docker-image status report.

The machine-readable source of truth is ``.tools/notebook-build-status.json``.
Publishing workflows append/update release evidence after each image build and
this script renders ``.tools/test-notebooks.md`` from that evidence plus the
current notebook configurations.

This report deliberately distinguishes image construction from scientific
notebook validation. The automated smoke test verifies that the container can
start Python/Jupyter and that ``pip check`` succeeds. It does not execute the
full notebook or validate a biological result.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

try:
    import yaml
except ImportError as exc:  # pragma: no cover - exercised by CLI environments
    raise SystemExit(
        "PyYAML is required. Install .tools/requirements.txt before running notebook_status.py."
    ) from exc

SCHEMA_VERSION = 1
DEFAULT_STATUS_PATH = Path(".tools/notebook-build-status.json")
DEFAULT_REPORT_PATH = Path(".tools/test-notebooks.md")
VALID_STATUSES = {"success", "failure", "cancelled", "skipped", "not_run", "unknown"}


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def normalize_status(value: Optional[str]) -> str:
    value = (value or "").strip().lower()
    if not value:
        return "not_run"
    aliases = {
        "succeeded": "success",
        "failed": "failure",
        "canceled": "cancelled",
        "not-run": "not_run",
        "not run": "not_run",
    }
    value = aliases.get(value, value)
    return value if value in VALID_STATUSES else "unknown"


def load_status(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {"schema_version": SCHEMA_VERSION, "notebooks": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    if data.get("schema_version") != SCHEMA_VERSION:
        raise ValueError(
            f"Unsupported notebook status schema {data.get('schema_version')!r}; expected {SCHEMA_VERSION}."
        )
    data.setdefault("notebooks", {})
    return data


def save_status(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def load_config(config_path: Path) -> Dict[str, Any]:
    with config_path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{config_path} does not contain a YAML mapping")
    return data


def config_metadata(config_path: Path, repo_root: Path) -> Dict[str, str]:
    data = load_config(config_path)
    dl4me = ((data.get("config") or {}).get("dl4miceverywhere") or {})
    rel = config_path.resolve().relative_to(repo_root.resolve()).as_posix()
    name = str(data.get("name") or config_path.parent.name)
    docker_tag = str(dl4me.get("docker_hub_image") or "")
    notebook_version = str(dl4me.get("notebook_version") or data.get("version") or "")
    return {
        "config_path": rel,
        "name": name,
        "docker_tag": docker_tag,
        "notebook_version": notebook_version,
        "category": config_path.parent.parent.name,
    }


def architecture_record(
    previous: Dict[str, Any],
    build_status: str,
    smoke_status: str,
    generated_at: str,
    attempted_at: str,
    image_tag: str,
) -> Dict[str, Any]:
    record = dict(previous or {})
    record["build_status"] = normalize_status(build_status)
    record["smoke_status"] = normalize_status(smoke_status)
    record["last_attempted_at"] = attempted_at
    record["image_tag"] = image_tag
    if record["build_status"] == "success":
        record["generated_at"] = generated_at or attempted_at
    return record


def compute_manifest_status(statuses: Iterable[str]) -> str:
    normalized = [normalize_status(value) for value in statuses]
    if "success" in normalized:
        return "success"
    if "failure" in normalized:
        return "failure"
    if "cancelled" in normalized:
        return "cancelled"
    if normalized and all(value == "skipped" for value in normalized):
        return "skipped"
    return "not_run"


def record_release(args: argparse.Namespace) -> None:
    repo_root = Path(args.repo_root).resolve()
    status_path = repo_root / args.status_file
    config_path = (repo_root / args.config).resolve()
    metadata = config_metadata(config_path, repo_root)
    tag = args.docker_tag or metadata["docker_tag"]
    if not tag:
        raise SystemExit(f"No Docker tag could be determined for {metadata['config_path']}")

    attempted_at = args.attempted_at or utc_now()
    run_url = args.run_url or ""
    commit_sha = args.commit_sha or ""

    data = load_status(status_path)
    notebook = data["notebooks"].setdefault(metadata["config_path"], {})
    notebook.update(
        {
            "name": metadata["name"],
            "category": metadata["category"],
            "notebook_version": metadata["notebook_version"],
            "latest_recorded_tag": tag,
        }
    )
    releases = notebook.setdefault("releases", {})
    release = releases.setdefault(tag, {})
    release.update(
        {
            "docker_tag": tag,
            "last_attempted_at": attempted_at,
            "run_url": run_url,
            "commit_sha": commit_sha,
        }
    )

    architectures = release.setdefault("architectures", {})
    architectures["amd64"] = architecture_record(
        architectures.get("amd64", {}),
        args.amd64_build,
        args.amd64_smoke,
        args.amd64_generated_at,
        attempted_at,
        f"{tag}-amd64",
    )
    architectures["gpu"] = architecture_record(
        architectures.get("gpu", {}),
        args.gpu_build,
        args.gpu_smoke,
        args.gpu_generated_at,
        attempted_at,
        f"{tag}-gpu",
    )
    architectures["arm64"] = architecture_record(
        architectures.get("arm64", {}),
        args.arm64_build,
        args.arm64_smoke,
        args.arm64_generated_at,
        attempted_at,
        f"{tag}-arm64",
    )
    release["manifest_status"] = compute_manifest_status(
        [args.multi_manifest, args.amd64_manifest, args.arm64_manifest]
    )

    save_status(status_path, data)



def dockerhub_access_token(username: str, secret: str) -> str:
    if not username or not secret:
        return ""
    payload = json.dumps({"identifier": username, "secret": secret}).encode("utf-8")
    request = urllib.request.Request(
        "https://hub.docker.com/v2/auth/token",
        data=payload,
        headers={"Content-Type": "application/json", "User-Agent": "DL4MicEverywhere-status/1"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        result = json.load(response)
    token = str(result.get("access_token") or "")
    if not token:
        raise RuntimeError("Docker Hub authentication succeeded but returned no access token")
    return token


def fetch_dockerhub_tag(namespace: str, repository: str, tag: str, access_token: str = "") -> Optional[Dict[str, Any]]:
    encoded_tag = urllib.parse.quote(tag, safe="")
    url = f"https://hub.docker.com/v2/namespaces/{namespace}/repositories/{repository}/tags/{encoded_tag}"
    headers = {"Accept": "application/json", "User-Agent": "DL4MicEverywhere-status/1"}
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        raise RuntimeError(f"Docker Hub returned HTTP {exc.code} while reading {tag}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Could not contact Docker Hub while reading {tag}: {exc}") from exc


def dockerhub_timestamp(tag_data: Dict[str, Any]) -> str:
    for key in ("last_updated", "tag_last_pushed", "last_pushed"):
        value = tag_data.get(key)
        if value:
            return str(value)
    return ""


def sync_dockerhub(args: argparse.Namespace) -> None:
    repo_root = Path(args.repo_root).resolve()
    status_path = repo_root / args.status_file
    data = load_status(status_path)
    access_token = dockerhub_access_token(args.username, args.token)

    for config_path in all_configs(repo_root):
        metadata = config_metadata(config_path, repo_root)
        tag = metadata["docker_tag"]
        if not tag:
            continue

        final_data = fetch_dockerhub_tag(args.namespace, args.repository, tag, access_token)
        arch_data = {
            "amd64": fetch_dockerhub_tag(args.namespace, args.repository, f"{tag}-amd64", access_token),
            "gpu": fetch_dockerhub_tag(args.namespace, args.repository, f"{tag}-gpu", access_token),
            "arm64": fetch_dockerhub_tag(args.namespace, args.repository, f"{tag}-arm64", access_token),
        }
        if final_data is None and not any(arch_data.values()):
            continue

        notebook = data["notebooks"].setdefault(metadata["config_path"], {})
        notebook.update(
            {
                "name": metadata["name"],
                "category": metadata["category"],
                "notebook_version": metadata["notebook_version"],
                "latest_recorded_tag": tag,
            }
        )
        release = notebook.setdefault("releases", {}).setdefault(tag, {"docker_tag": tag})
        release["docker_tag"] = tag
        if final_data is not None:
            release["manifest_status"] = "success"
            final_updated = dockerhub_timestamp(final_data)
            if final_updated:
                release["dockerhub_last_updated"] = final_updated

        architectures = release.setdefault("architectures", {})
        for arch, tag_data in arch_data.items():
            if tag_data is None:
                continue
            previous = dict(architectures.get(arch) or {})
            generated_at = dockerhub_timestamp(tag_data)
            previous["build_status"] = "success"
            previous.setdefault("smoke_status", "not_run")
            previous["image_tag"] = f"{tag}-{arch}"
            if generated_at:
                previous["generated_at"] = generated_at
                previous.setdefault("last_attempted_at", generated_at)
            architectures[arch] = previous

    save_status(status_path, data)

def all_configs(repo_root: Path) -> list[Path]:
    return sorted((repo_root / "notebooks").glob("*/*/configuration.yaml"))


def latest_release(notebook: Dict[str, Any], preferred_tag: str) -> Optional[Dict[str, Any]]:
    releases = notebook.get("releases") or {}
    if preferred_tag and preferred_tag in releases:
        return releases[preferred_tag]
    if not releases:
        return None
    return max(
        releases.values(),
        key=lambda item: str(item.get("last_attempted_at") or ""),
    )


def short_timestamp(value: Optional[str]) -> str:
    if not value:
        return "—"
    text = str(value)
    try:
        parsed = dt.datetime.fromisoformat(text.replace("Z", "+00:00"))
        return parsed.astimezone(dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    except ValueError:
        return text


def status_icon(status: str) -> str:
    return {
        "success": "✅",
        "failure": "❌",
        "cancelled": "⚠️",
        "skipped": "⏭️",
        "not_run": "⬜",
        "unknown": "❔",
    }.get(normalize_status(status), "❔")


def build_cell(record: Optional[Dict[str, Any]]) -> str:
    if not record:
        return "⬜ Not recorded"
    status = normalize_status(record.get("build_status"))
    if status == "success":
        return f"✅ Built<br><sub>{short_timestamp(record.get('generated_at'))}</sub>"
    if status == "failure":
        return f"❌ Failed<br><sub>{short_timestamp(record.get('last_attempted_at'))}</sub>"
    labels = {
        "cancelled": "Cancelled",
        "skipped": "Skipped",
        "not_run": "Not run",
        "unknown": "Unknown",
    }
    return f"{status_icon(status)} {labels.get(status, status)}"


def smoke_cell(record: Optional[Dict[str, Any]]) -> str:
    if not record:
        return "⬜ Not recorded"
    status = normalize_status(record.get("smoke_status"))
    labels = {
        "success": "Passed",
        "failure": "Failed",
        "cancelled": "Cancelled",
        "skipped": "Skipped",
        "not_run": "Not run",
        "unknown": "Unknown",
    }
    return f"{status_icon(status)} {labels.get(status, status)}"


def manifest_cell(release: Optional[Dict[str, Any]]) -> str:
    if not release:
        return "⬜ Not recorded"
    status = normalize_status(release.get("manifest_status"))
    labels = {
        "success": "Published",
        "failure": "Failed",
        "cancelled": "Cancelled",
        "skipped": "Skipped",
        "not_run": "Not run",
        "unknown": "Unknown",
    }
    return f"{status_icon(status)} {labels.get(status, status)}"


def latest_generated(release: Optional[Dict[str, Any]]) -> str:
    if not release:
        return "—"
    values = [
        str(item.get("generated_at"))
        for item in (release.get("architectures") or {}).values()
        if item.get("generated_at")
    ]
    if not values:
        return "—"
    return short_timestamp(max(values))


def escape_md(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def render_report(args: argparse.Namespace) -> None:
    repo_root = Path(args.repo_root).resolve()
    status_path = repo_root / args.status_file
    report_path = repo_root / args.report_file
    data = load_status(status_path)

    rows = []
    for config_path in all_configs(repo_root):
        metadata = config_metadata(config_path, repo_root)
        notebook = data.get("notebooks", {}).get(metadata["config_path"], {})
        release = latest_release(notebook, metadata["docker_tag"])
        architectures = (release or {}).get("architectures") or {}
        recorded_tag = (release or {}).get("docker_tag") or metadata["docker_tag"] or "—"
        run_url = (release or {}).get("run_url") or ""
        tag_cell = f"`{escape_md(recorded_tag)}`"
        if run_url:
            tag_cell += f"<br><sub>[CI run]({escape_md(run_url)})</sub>"
        rows.append(
            [
                metadata["name"],
                tag_cell,
                build_cell(architectures.get("amd64")),
                smoke_cell(architectures.get("amd64")),
                build_cell(architectures.get("gpu")),
                smoke_cell(architectures.get("gpu")),
                build_cell(architectures.get("arm64")),
                smoke_cell(architectures.get("arm64")),
                manifest_cell(release),
                latest_generated(release),
            ]
        )

    header = [
        "Notebook",
        "Release tag",
        "AMD64 build",
        "AMD64 smoke",
        "GPU build",
        "GPU-image smoke",
        "ARM64 build",
        "ARM64 smoke",
        "Final tag",
        "Latest generated",
    ]

    lines = [
        "<!-- AUTO-GENERATED by .tools/python_tools/notebook_status.py. DO NOT EDIT MANUALLY. -->",
        "# DL4MicEverywhere automated Docker image status",
        "",
        "This report is maintained automatically by the Docker-image publishing workflows.",
        "The timestamp is recorded when an architecture-specific image is successfully built and pushed.",
        "",
        "**Build** means Docker successfully produced and pushed that image. **Smoke** means the generated",
        "container subsequently passed the lightweight DL4MicEverywhere checks (`python --version`,",
        "`pip check`, and `jupyter --version`). The GPU-image smoke test checks the GPU image as a container",
        "but does **not** claim that CUDA/TensorFlow/PyTorch GPU execution was validated unless a dedicated",
        "GPU runner is added in the future. These checks do not execute the complete scientific notebook.",
        "",
        "Historical hand-maintained notebook compatibility notes are preserved in",
        "[`.tools/test-notebooks-legacy.md`](test-notebooks-legacy.md).",
        "",
        "Legend: ✅ success · ❌ failure · ⚠️ cancelled · ⏭️ skipped · ⬜ not yet recorded · ❔ unknown",
        "",
        "| " + " | ".join(header) + " |",
        "| " + " | ".join(["---"] * len(header)) + " |",
    ]
    for row in rows:
        lines.append("| " + " | ".join(escape_md(str(cell)) for cell in row) + " |")
    lines.append("")

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--status-file", default=str(DEFAULT_STATUS_PATH))
    parser.add_argument("--report-file", default=str(DEFAULT_REPORT_PATH))
    subparsers = parser.add_subparsers(dest="command", required=True)

    record = subparsers.add_parser("record", help="Record the result of one notebook image publishing run")
    record.add_argument("--config", required=True)
    record.add_argument("--docker-tag", default="")
    record.add_argument("--amd64-build", default="not_run")
    record.add_argument("--amd64-smoke", default="not_run")
    record.add_argument("--amd64-generated-at", default="")
    record.add_argument("--gpu-build", default="not_run")
    record.add_argument("--gpu-smoke", default="not_run")
    record.add_argument("--gpu-generated-at", default="")
    record.add_argument("--arm64-build", default="not_run")
    record.add_argument("--arm64-smoke", default="not_run")
    record.add_argument("--arm64-generated-at", default="")
    record.add_argument("--multi-manifest", default="not_run")
    record.add_argument("--amd64-manifest", default="not_run")
    record.add_argument("--arm64-manifest", default="not_run")
    record.add_argument("--attempted-at", default="")
    record.add_argument("--run-url", default="")
    record.add_argument("--commit-sha", default="")
    record.set_defaults(func=record_release)

    sync = subparsers.add_parser("sync-dockerhub", help="Import current published tags and timestamps from Docker Hub")
    sync.add_argument("--namespace", default="henriqueslab")
    sync.add_argument("--repository", default="dl4miceverywhere")
    sync.add_argument("--username", default=os.environ.get("DOCKERHUB_USERNAME", ""))
    sync.add_argument("--token", default=os.environ.get("DOCKERHUB_TOKEN", ""))
    sync.set_defaults(func=sync_dockerhub)

    render = subparsers.add_parser("render", help="Render .tools/test-notebooks.md from the status JSON")
    render.set_defaults(func=render_report)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
