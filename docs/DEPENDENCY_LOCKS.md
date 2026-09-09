# Deterministic Python dependency locks

DL4MicEverywhere separates the dependency file that a notebook author edits from the fully resolved file used to build the Docker image.

## Files and responsibilities

Every bundled notebook directory contains these files:

```text
configuration.yaml
requirements.txt
requirements.lock.txt   # generated
```

`configuration.yaml` records the real immutable source/provenance URL for the dependency specification:

```yaml
config:
  dl4miceverywhere:
    requirements_url: https://raw.githubusercontent.com/OWNER/REPOSITORY/<40-char-commit>/path/to/requirements.txt
```

`requirements.txt` is the committed build input and the source of truth for notebook authors inside DL4MicEverywhere. Keep it small and readable: list direct dependencies and intentional constraints there. It may contain exact pins or deliberate version ranges when the notebook genuinely supports them. For bundled notebooks, normal builds use this local file rather than downloading `requirements_url`.

`requirements.lock.txt` is generated automatically beside `configuration.yaml`. It contains the complete resolved dependency graph and package hashes. Authors should never edit it manually.

There is deliberately no `lock_url`, `requirements_lock`, or lock commit field in `configuration.yaml`. The sibling lock location is a DL4MicEverywhere repository convention.

For migrated notebooks, `requirements.txt` also includes a comment with the immutable upstream dependency source from which it was imported. This mirrors `requirements_url` for convenient provenance; Docker does not install the upstream requirements file.

## Normal Docker builds

A normal local image build validates the sibling lock before invoking Docker. If the lock is valid, no dependency resolution or package update is performed.

Docker installs only:

```bash
python -m pip install --require-hashes -r requirements.lock.txt
```

The human-edited `requirements.txt` is never installed directly into the image.

Using an existing local image or pulling an existing image from Docker Hub does not generate, resolve, or update dependency locks.

## Runtime packages

DL4MicEverywhere needs a small Jupyter runtime in addition to notebook-specific dependencies. The default runtime inputs are versioned in:

```text
.tools/lock_profiles/
```

The lock generator combines the notebook's `requirements.txt` with the profile appropriate for the configured Python version. If the notebook input already names one of the runtime packages, the notebook value wins and the default is not added. The final Python environment is then resolved once as a single dependency graph.

The notebook-conversion stage has an independent input and lock:

```text
docker/converter-requirements.txt
docker/converter-requirements.lock.txt
```

so converter dependencies cannot drift independently either.

## Automatic lock generation

Lock generation is performed by `.tools/python_tools/requirements_lock.py` with a pinned `uv` resolver version. If that exact `uv` version is not available, DL4MicEverywhere creates a private resolver environment under `.tools/.cache/uv/` and installs only that pinned resolver version there.

A generated lock header records:

- the local dependency input path;
- the SHA-256 of `requirements.txt`;
- the target Python version;
- the runtime profile and its SHA-256;
- the exact resolver version;
- the `uv --exclude-newer` resolution cutoff;
- the SHA-256 of the merged resolver input;
- the SHA-256 of the generated lock body.

Changing `requirements.txt`, the target Python version, the relevant runtime profile, or the lock format makes the previous lock stale automatically.

For clean Git checkouts, the `--exclude-newer` cutoff is anchored to the newest Git commit timestamp of the local dependency input/runtime profile, so CI runs at different wall-clock times still resolve against the same package horizon. Dirty working copies and release ZIPs fall back to the current UTC day. Once a valid lock exists, normal builds leave it untouched.

## GitHub maintenance

`.github/workflows/update_dependency_locks.yml` regenerates missing or stale locks after relevant changes on `main` and commits generated lock files back to the repository.

Changing a notebook's `requirements.txt` also triggers the Docker build workflow for that notebook. Global runtime-profile or lock-tool changes trigger the all-images build workflow.

Docker image workflows run the same lock validation before Buildx, so they can build correctly even if the lock-maintenance commit has not landed yet.

## Maintainer commands

Automation should normally make manual lock maintenance unnecessary. The equivalent local commands are available for testing:

```bash
make locks
make check-locks
```

`make locks` regenerates only missing or stale locks. `make check-locks` never modifies files.

## Updating dependencies

The intended contributor workflow is:

1. Edit the notebook's local `requirements.txt`.
2. Commit the change normally.
3. Let the lock-maintenance workflow resolve and store `requirements.lock.txt`.
4. Let the notebook-image workflow rebuild and test the image against that lock.

No lock URL or manual lock update is required.

## Scope of reproducibility

These locks freeze the Python dependency graph and package artifacts selected for the target Python/Linux environment. Full bit-for-bit Docker reproducibility additionally requires immutable base-image digests and deterministic OS package sources; those are a separate reproducibility layer.
