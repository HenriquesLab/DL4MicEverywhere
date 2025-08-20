# Cheatsheet for DL4MicEverywhere maintainers

The information in this file is not part of DL4MicEverywhere userguide but for the team to get quick guides on how to interact with DL4MicEverywhere development

## Running CI actions from Linux Workstaiton
In the terminal
```
bash actions-runner/run.sh
```
The output of these actions can be seen here: https://github.com/HenriquesLab/DL4MicEverywhere/settings/actions/runners

## Manually updating a specfic Docker Image in Docker Hub
Run the following GitHub action by clicking on **Run workflow** and adding the path to the specific configuration `yaml` of the notebook: https://github.com/HenriquesLab/DL4MicEverywhere/actions/workflows/build_docker_images_aux.yml
(for `pix2pix` it would be `https://github.com/HenriquesLab/DL4MicEverywhere/actions/workflows/build_docker_images_aux.yml`)

## Keep ZeroCostDL4Mic synchronised with DL4MicEverywhere
When updating a notebook in ZeroCostDL4Mic one should ensure that the version is updated in the following files: 
- Notebook itself (in load dependencies and desirably, in the change log at the end of the notebook)
- [Latest Notebook Version (CSV)](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv)
- If needed, the respective [requirements file](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/requirements_files) should be updated
- [Manifest YAML](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml), in the `version` field of the notebook (specified as `application`) and in the `notebook_version` field inside the `config/dl4miceverywhere` field

These changes will trigger the GitHub action to update DL4MicEverywhere accordingly, which usually runs at night. Yet, one could run it manually with the [Check ZeroCost Versions action](https://github.com/HenriquesLab/DL4MicEverywhere/actions/workflows/check_zerocost_versions.yml)

