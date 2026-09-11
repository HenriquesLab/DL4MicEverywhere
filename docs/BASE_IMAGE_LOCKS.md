# Immutable Docker base-image locks

DL4MicEverywhere keeps notebook configurations modular: `configuration.yaml`
still declares values such as `ubuntu_version` and `cuda_version`. Those values
are converted to the same logical Docker tags as before:

- CPU: `ubuntu:<ubuntu_version>`
- GPU: `nvidia/cuda:<cuda_version>-devel-ubuntu<ubuntu_version>`
- notebook converter: `python:3.9.20-alpine3.19`

Docker tags can be republished. Therefore a tag alone is not a deterministic
build input. DL4MicEverywhere resolves each logical tag once and stores the
immutable registry digest in:

```
.tools/base_images.lock.yaml
```

A normal build then uses references such as:

```
ubuntu:22.04@sha256:<immutable-index-digest>
```

rather than `ubuntu:22.04` directly.

## Why the lock uses the index digest

The CPU images are built for both `linux/amd64` and `linux/arm64`. For a
multi-platform image, the registry index (manifest-list) digest is immutable and
still lets BuildKit choose the correct platform manifest. The lock additionally
records the platform-specific manifest digests returned by Docker Buildx for
validation and auditability.

## Automatic maintenance

`.tools/python_tools/base_image_lock.py` is the single source of truth for
constructing logical base-image tags and resolving them with:

```
docker buildx imagetools inspect
```

The normal behavior is intentionally conservative:

```
python3 .tools/python_tools/base_image_lock.py --repo-root . ensure-all
```

This **adds missing entries only**. It never changes an existing digest.
Therefore rebuilding the same committed configuration continues to use the
same base image even if Docker Hub later republishes the tag.

Local image builds also call `ensure-for-build`. If a developer is working from
a ZIP or a new configuration whose base image has not yet been committed to the
lock, the missing entry is resolved automatically and written to the local lock.
No manual digest lookup is required.

## GitHub Actions

`.github/workflows/update_base_image_locks.yml` runs when notebook
configurations or base-image selection code change. It resolves any newly
required tags, validates that all bundled configurations are covered, and
commits the generated lock file.

Existing pins are updated only through the workflow's explicit
`refresh_existing` option. An intentional refresh updates the digests and
commits the new lock. It does **not** automatically republish images under their
old version tags: published versioned Docker tags are treated as immutable.
After a base-image refresh, update the appropriate DL4MicEverywhere/image
version first so the publishing workflow generates a new Docker tag.

## Local commands

```
make base-locks
make check-base-locks
```

To intentionally update all currently required base images:

```
make refresh-base-locks
```

`refresh-base-locks` is a maintenance operation and should be followed by the
normal image validation/release process.

## Build-time enforcement

All four Dockerfiles require two pre-resolved arguments:

- `CONVERTER_BASE_IMAGE`
- `FINAL_BASE_IMAGE`

They are used directly by `FROM`. The Dockerfiles provide no mutable default,
so bypassing the lock machinery causes the build to fail instead of silently
falling back to an unpinned tag.

The exact pinned converter and final base-image references are also recorded in
`/home/docker_info.txt` inside the built image.
