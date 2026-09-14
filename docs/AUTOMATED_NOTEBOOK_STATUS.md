# Automated notebook Docker-image status

`.tools/test-notebooks.md` is an automatically generated report of the Docker images produced by DL4MicEverywhere.
It must not be edited by hand.

## Source of truth

The machine-readable history is stored in:

```text
.tools/notebook-build-status.json
```

Each notebook configuration can contain multiple recorded release tags. For each release the status file keeps the
AMD64, GPU-image and ARM64 build outcomes, the lightweight smoke-test outcomes, the successful image-generation
timestamps, the final manifest publication status, the GitHub Actions run URL and the source commit SHA when those
values are known.

`.tools/python_tools/notebook_status.py` renders that JSON together with the current `configuration.yaml` files into:

```text
.tools/test-notebooks.md
```

The old manually maintained compatibility table is preserved as `.tools/test-notebooks-legacy.md`.

## What is recorded automatically after a build

Both reusable Docker publishing workflows expose the outcome of their architecture-specific Buildx steps. After a
successful push, the generated image is pulled back and checked with `.tools/bash_tools/post_build_test.sh`.

The automated smoke test verifies:

- Python starts;
- `python -m pip check` reports a consistent Python environment;
- Jupyter starts.

The GPU-image smoke test currently checks the GPU image as a normal container. It does **not** claim that CUDA,
TensorFlow or PyTorch GPU execution worked because the image-building runner is not guaranteed to expose an NVIDIA
GPU to Docker. Full scientific notebook execution is also outside the scope of this report.

Smoke tests are intentionally non-gating: their result is recorded, but a failed smoke test does not erase the fact
that an image was successfully generated and pushed.

## Timestamps

The architecture-specific generation timestamp is captured immediately after `docker/build-push-action` completes
successfully. The generated Markdown therefore shows when each image was produced rather than merely when the report
was rendered.

## Existing images and Docker Hub synchronization

The repository already contains many published immutable version tags that predate the automated report. Because the
pre-build duplicate-tag guard correctly prevents those releases from being rebuilt, the workflow
`.github/workflows/sync_notebook_image_status.yml` imports their current Docker Hub tag metadata.

For each configured release it checks the final tag and the `-amd64`, `-gpu`, and `-arm64` tags. Existing tags are
recorded as published/generated using Docker Hub's `last_updated` timestamp. For legacy images this is the registry
tag publication/update time rather than a reconstructed build-start time. New DL4MicEverywhere builds use the CI
timestamp captured immediately after the successful push. A Docker Hub synchronization never pretends that a smoke
test ran: the smoke result stays `Not run` unless DL4MicEverywhere CI actually executed it.

The synchronization can be started manually and also runs weekly as a reconciliation check. After this feature is
first pushed, run **Sync notebook image status from Docker Hub** once to bootstrap the already published current tags.
Normal new image builds update the report immediately, so the weekly job is mainly useful for reconciliation and for
detecting images published outside the normal workflow.

## Concurrent builds

`Build and push all Docker Images` can finish many notebook builds at almost the same time. The expensive builds remain
parallel. Only the small final report-writing workflow is serialized using a repository/ref-specific GitHub Actions
concurrency group. This prevents simultaneous jobs from racing while modifying the shared JSON and Markdown files.

## Manual commands

Render the report from the current JSON:

```bash
python .tools/python_tools/notebook_status.py --repo-root . render
```

Import current Docker Hub publication timestamps (credentials may be supplied through `DOCKERHUB_USERNAME` and
`DOCKERHUB_TOKEN`):

```bash
python .tools/python_tools/notebook_status.py --repo-root . sync-dockerhub
python .tools/python_tools/notebook_status.py --repo-root . render
```

`test_files.py` remains as a backwards-compatible wrapper and renders the new report when run without arguments.
