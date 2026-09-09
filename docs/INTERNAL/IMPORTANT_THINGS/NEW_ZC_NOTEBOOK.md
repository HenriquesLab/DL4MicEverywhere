# What to Do When Creating a New ZeroCostDL4Mic Notebook?

There are a few steps to follow when adding a new ZeroCostDL4Mic notebook. The source notebook lives in ZeroCostDL4Mic, while DL4MicEverywhere stores the deterministic dependency input and generated lock used for Docker builds.

## On ZeroCostDL4Mic

1. **Create the notebook** in the appropriate ZeroCostDL4Mic notebook folder and follow the project template/conventions.
2. **Update its notebook version** in ZeroCostDL4Mic's version metadata.
3. **Maintain the notebook's simple requirements specification** in ZeroCostDL4Mic as usual. This remains useful as the upstream dependency reference.
4. **Update the ZeroCostDL4Mic manifest** as required by that project.

## On DL4MicEverywhere

1. **Create a notebook folder** under `notebooks/ZeroCostDL4Mic_notebooks/`, using the usual `NOTEBOOK_NAME_DL4Mic` naming convention.

2. **Create `configuration.yaml`** using an existing notebook as a template.
   - Set `notebook_url` to a raw GitHub URL containing the full 40-character ZeroCostDL4Mic commit SHA. Do not use `main` or `master` for a build input.
   - Set `requirements_url` to the immutable raw URL of the selected upstream dependency specification:

     ```yaml
     requirements_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/<commit>/requirements_files/NOTEBOOK_NAME_requirements_simple.txt
     ```

3. **Create `requirements.txt` beside `configuration.yaml`.** Copy/review the direct dependency specification from the `requirements_url` selected above. This local file is the deterministic input used for lock generation. A useful header is:

   ```text
   # Migrated/source dependency reference:
   # https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/<commit>/requirements_files/NOTEBOOK_NAME_requirements_simple.txt
   ```

   Edit `requirements.txt`, not `requirements.lock.txt`, when dependency requirements change.

4. **Do not create or reference a lock URL.** DL4MicEverywhere automatically generates the sibling `requirements.lock.txt`, containing exact transitive versions and package hashes. CI stores the generated lock in the repository.

5. **Update the name parser** in `.tools/python_tools/dict_parser.py` if the new notebook naming requires a new mapping.

6. **Add the notebook to tests** in `.tools/python_tools/test_files.py` as appropriate.

See [Dependency Locks](../../DEPENDENCY_LOCKS.md) and [Configuration Format](../../FORMAT.md) for the current deterministic build model.
