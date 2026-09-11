# Reproducible Docker builds

DL4MicEverywhere treats notebook sources, Python dependencies, and its own conversion tooling as explicit build inputs.

## Notebook sources

Remote `raw.githubusercontent.com` notebook URLs used for bundled builds must contain a full 40-character Git commit SHA. The launcher rejects floating GitHub notebook build URLs such as `main` or `master`.

DL4MicEverywhere itself is not cloned during the image build. The notebook converter and Docker-info writer are copied from the local repository used as Docker build context, so a release ZIP and a Git checkout use the exact converter code that launched the build without maintaining a self-referential commit value.

## Python dependencies

Every bundled notebook stores a local, human-editable `requirements.txt` beside `configuration.yaml`. The YAML keeps the immutable dependency source URL, for example:

```yaml
requirements_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/<40-char-commit>/requirements_files/CARE_2D_requirements_simple.txt
```

The committed sibling `requirements.txt` is the deterministic build input; the URL is retained as source/provenance. The input is never installed directly. DL4MicEverywhere automatically derives the sibling `requirements.lock.txt`, containing exact transitive versions and package hashes, and Docker installs only that lock with `pip --require-hashes`.

DL4MicEverywhere runtime packages are incorporated into the same resolution, with notebook-specific constraints taking precedence. The converter stage has an independent lock. See [DEPENDENCY_LOCKS.md](DEPENDENCY_LOCKS.md) for the complete workflow.

## Docker base images

The modular Ubuntu/CUDA settings in `configuration.yaml` are resolved through the committed [`base_images.lock.yaml`](../.tools/base_images.lock.yaml). The lock maps the logical CPU, GPU, and notebook-converter image tags to immutable registry index digests. All Dockerfiles receive pre-resolved `CONVERTER_BASE_IMAGE` and `FINAL_BASE_IMAGE` references and use those values directly in `FROM`. See [BASE_IMAGE_LOCKS.md](BASE_IMAGE_LOCKS.md).

## Other deterministic inputs

- NVM's installer is fetched from an immutable commit.
- pip, setuptools, and wheel bootstrap versions are explicit and Python-version compatible.
- Timestamp-based Docker cache busting is not used.
- pip's online version check is disabled in image builds.

## Updating a notebook intentionally

1. Review and select the new upstream notebook commit.
2. Put its full 40-character SHA in `notebook_url`.
3. Set `requirements_url` to the immutable dependency source associated with that notebook revision.
4. Edit the local `requirements.txt` to match that source/environment.
5. Commit the configuration and dependency input.
6. Let the lock workflow regenerate `requirements.lock.txt` and the image workflow build/test the resulting image.

There is no duplicated source-repository field, source-commit field, lock URL, or DL4MicEverywhere self-commit field to synchronize.

## Remaining sources of variability

Python dependencies and Docker base images are now locked, but the complete image is not yet bit-for-bit reproducible because:

- `apt-get install` obtains package revisions from repositories available at build time.
- CPU architecture and Docker/BuildKit implementation can affect binary artifacts.

A future reproducibility layer can use snapshot/immutable OS package repositories for the `apt` layer.
