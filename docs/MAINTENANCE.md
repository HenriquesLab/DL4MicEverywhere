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
