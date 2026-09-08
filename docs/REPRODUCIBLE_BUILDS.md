# Reproducible Docker builds

DL4MicEverywhere treats notebook image inputs as immutable build inputs while keeping notebook metadata separate from build-infrastructure metadata.

## What is pinned

- `notebook_url` and remote `requirements_url` values point directly to immutable 40-character Git commit SHAs rather than `main` or `master`.
- The launcher validates `raw.githubusercontent.com` build URLs and rejects them when the URL does not contain a full commit SHA.
- The Docker templates do not clone DL4MicEverywhere from GitHub. They `COPY` the notebook-conversion package and `create_docker_info.py` directly from the local repository used as the Docker build context.
- This means the converter automatically matches the exact local DL4MicEverywhere source being run, including release ZIPs that do not contain `.git` metadata. Docker fingerprints these copied files as build inputs.
- The notebook conversion stage uses a Python patch-version tag (`python:3.9.20-alpine3.19`).
- NVM's installer is fetched from the immutable commit behind NVM v0.39.7.
- pip/setuptools/wheel bootstrap versions are exact and Python-version compatible.
- Notebook requirements are checked before installation; floating requirements such as `numpy>=1.20`, `numpy`, VCS URLs, and direct URLs are rejected.
- The three bundled upstream requirement files that contained floating specifications (`CycleGAN`, `pix2pix`, and `fnet_3D`) use repository-local `requirements.lock.txt` files. Their immutable upstream requirement URL is retained as `requirements_source_url` for provenance.
- Timestamp-based `CACHEBUST` invalidation is removed, and pip's online version check is disabled.

## Updating a notebook intentionally

When a notebook source is updated:

1. Choose and review the new upstream Git commit.
2. Put its full 40-character SHA directly in `notebook_url` and, when requirements are remote, `requirements_url`.
3. Verify every requirement used for the build has an exact version.
4. Build and run the pre/post-build checks.
5. Only then publish a new DL4MicEverywhere notebook/image version.

There is no separate `source_commit` or `source_repository` field to keep synchronized with these URLs.

## Updating DL4MicEverywhere build infrastructure intentionally

No self-referential commit value needs to be maintained. The Docker build uses the converter files directly from the local DL4MicEverywhere repository that launched the build.

Therefore, updating the build infrastructure is simply a normal code change to `.tools/notebook_autoconversion/` or `.tools/python_tools/create_docker_info.py`. Once that repository state is checked out or distributed as a release ZIP, builds automatically use that exact local implementation.

## Remaining sources of variability

This pins Git inputs and declared Python package versions, but it is not yet a bit-for-bit image lock. The following can still change over time:

- Ubuntu and NVIDIA CUDA base-image tags are not yet pinned by digest.
- `apt-get install` obtains package revisions from repositories available at build time.
- Python packages can have transitive dependencies whose own version ranges are defined in package metadata even when the top-level requirement is exact.
- CPU architecture and Docker builder implementation can affect binary artifacts.

For a stronger next phase, pin base images by digest, use Ubuntu snapshot repositories (or exact `.deb` artifacts), and generate per-notebook Python lock files with hashes for the complete transitive dependency graph.
