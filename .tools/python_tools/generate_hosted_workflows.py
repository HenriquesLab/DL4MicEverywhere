"""Generate GitHub-hosted copies of the workflows that need self-hosted runners.

Each workflow in SOURCES is copied to `.github/workflows/gh_hosted_<name>.yml`
with these changes:

* every self-hosted runner is replaced by a GitHub-hosted one
  (`ubuntu-latest` for x86-64, `ubuntu-24.04-arm` for ARM64);
* calls to other self-hosted workflows point to their gh_hosted_ copies;
* automatic triggers (push, release, schedule) are removed, so a copy only
  runs when started by hand and never alongside the self-hosted original;
* the Docker build jobs free disk space first, because GitHub-hosted runners
  start with only about 14 GB free.

The copies are generated, not edited: change the original workflow, then run

    python3 .tools/python_tools/generate_hosted_workflows.py

`--check` exits with status 1 when a copy is out of date (used by the tests).
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = REPO_ROOT / ".github" / "workflows"
PREFIX = "gh_hosted_"

# Workflow file -> whether its triggers are replaced by workflow_dispatch only.
# Reusable workflows keep their triggers: they only run when a caller starts them.
SOURCES = {
    "build_docker_images_all.yml": True,
    "build_docker_images_aux.yml": False,
    "build_docker_images_new_config.yml": False,
    "check_zerocost_versions.yml": True,
    "update_configs_manifest.yml": True,
}

RUNNERS = {
    r"\[self-hosted, Ubuntu, NotDocker\]": "ubuntu-latest",
    r"\[self-hosted, macOS, ARM64\]": "ubuntu-24.04-arm",
}

MANUAL_TRIGGER = """on:
  # GitHub-hosted copy: manual only, so it never runs alongside the self-hosted
  # workflow on the same push, release or schedule.
  workflow_dispatch:

"""

FREE_DISK_STEP = """
      - name: Free disk space on the GitHub-hosted runner
        # GitHub-hosted runners start with about 14 GB free, less than a CUDA
        # base image plus deep-learning wheels need. Remove preinstalled
        # toolchains that DL4MicEverywhere does not use.
        shell: bash
        run: |
          df -h /
          sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/.ghcup \\
            /opt/hostedtoolcache/CodeQL /usr/local/share/boost /usr/share/swift \\
            /usr/local/share/powershell /usr/local/share/chromium /opt/az /opt/microsoft || true
          docker image prune --all --force || true
          df -h /
"""

GPU_SPACE_STEP = """      - name: Free disk space before the GPU image
        # The CPU image and its build cache are no longer needed on this runner.
        shell: bash
        run: |
          docker image rm -f "henriqueslab/dl4miceverywhere:${{ needs.get_arguments.outputs.docker_tag }}-amd64" 2>/dev/null || true
          docker buildx prune --all --force || true
          df -h /

"""

PYYAML_STEPS = """
      - name: Set up Python for the configuration scripts
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install PyYAML for the configuration scripts
        run: pip install pyyaml==6.0.1
"""

CHECKOUT = "      - name: Clone DL4MicEverywhere repository\n        uses: actions/checkout@v4\n"


def job_span(text: str, job: str) -> tuple[int, int]:
    """Return the start and end offsets of a top-level job."""
    start = text.index(f"\n  {job}:\n") + 1
    following = re.search(r"\n  [A-Za-z0-9_]+:\n", text[start + 1:])
    end = start + 1 + following.start() + 1 if following else len(text)
    return start, end


def insert_after_checkout(text: str, job: str, steps: str) -> str:
    start, end = job_span(text, job)
    body = text[start:end]
    if CHECKOUT not in body:
        raise ValueError(f"job {job}: checkout step not found")
    body = body.replace(CHECKOUT, CHECKOUT + steps, 1)
    return text[:start] + body + text[end:]


def replace_triggers(text: str) -> str:
    match = re.search(r"^on:\n.*?(?=^[A-Za-z_]+:)", text, re.MULTILINE | re.DOTALL)
    if not match:
        raise ValueError("top-level `on:` block not found")
    return text[:match.start()] + MANUAL_TRIGGER + text[match.end():]


def transform(name: str, text: str, manual_only: bool) -> str:
    text = text.replace("\r\n", "\n")
    first_line, rest = text.split("\n", 1)
    if not first_line.startswith("name: "):
        raise ValueError(f"{name}: the first line must be the workflow name")
    title = first_line[len("name: "):].strip().strip("'\"")
    text = f'name: "[GitHub-hosted] {title}"\n' + rest

    if manual_only:
        text = replace_triggers(text)

    for pattern, runner in RUNNERS.items():
        text = re.sub(r"runs-on:\s+" + pattern, f"runs-on: {runner}", text)

    for source in SOURCES:
        text = text.replace(f"uses: ./.github/workflows/{source}", f"uses: ./.github/workflows/{PREFIX}{source}")

    if "\n  build_amd64:\n" in text:
        # The configuration scripts need PyYAML, which the self-hosted runner
        # has preinstalled. Add it where the job does not install it itself.
        start, end = job_span(text, "get_arguments")
        if "pip install" not in text[start:end]:
            text = insert_after_checkout(text, "get_arguments", PYYAML_STEPS)
        for job in ("build_amd64", "build_arm64"):
            text = insert_after_checkout(text, job, FREE_DISK_STEP)
        gpu = "      - name: Build and push GPU image\n"
        if text.count(gpu) != 1:
            raise ValueError(f"{name}: GPU build step not found exactly once")
        text = text.replace(gpu, GPU_SPACE_STEP + gpu)

    if "self-hosted" in re.sub(r"#.*", "", text):
        raise ValueError(f"{name}: a self-hosted runner is left after the conversion")

    header = (
        f"# GENERATED from {name} by .tools/python_tools/generate_hosted_workflows.py.\n"
        "# Do not edit by hand: change the original workflow and run the generator again.\n"
        "# Runs on GitHub-hosted runners instead of the self-hosted ones.\n"
    )
    return header + text


def generate() -> dict[Path, str]:
    outputs = {}
    for name, manual_only in SOURCES.items():
        source = (WORKFLOWS / name).read_text(encoding="utf-8")
        outputs[WORKFLOWS / f"{PREFIX}{name}"] = transform(name, source, manual_only)
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="fail if a generated copy is out of date")
    args = parser.parse_args()

    stale = []
    for path, content in generate().items():
        current = path.read_text(encoding="utf-8").replace("\r\n", "\n") if path.exists() else None
        if current == content:
            continue
        if args.check:
            stale.append(path.name)
        else:
            path.write_text(content, encoding="utf-8", newline="\n")
            print(f"Wrote {path.relative_to(REPO_ROOT)}")
    if stale:
        print("Out of date (run generate_hosted_workflows.py): " + ", ".join(stale), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
