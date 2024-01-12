# Format of YAML Configuration Files for DL4MicEverywhere

The containerization of a notebook in a static environment is defined by `configuration.yaml` files. These files are easily readable and detail the parameters required for Docker container creation. A [collection of configuration files](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks) for different notebooks is already available. However, users have the flexibility to create and use their own. 

The structure that these YAML files need to follow to properly work is:

* **`config`**:
    * **`dl4miceveryhwere`**:
        * **`notebook_url`**: The URL to download the Jupyter notebook that will be stored inside the docker image.
        * **`requirements_url`**: The URL to download the file specifying the Python library and the versions that will be included in the docker image.
        * **`cuda_version`**: The CUDA version to be included in the docker image. The provided CUDA version will be used to pull the Ubuntu image from Docker Hub (from [Nvidia](https://hub.docker.com/r/nvidia/dcgm-exporter) if GPU is selected), therefore its version (and the `ubuntu_version`) should be one from the following [list](https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md).
        * **`ubuntu_version`**: The Ubuntu version to be used as the operating system in the docker image. Similarly, the Ubuntu version will be used to pull the base image from Docker Hub (from [Nvidia](https://hub.docker.com/r/nvidia/dcgm-exporter) if GPU is selected and from [Ubuntu](https://hub.docker.com/_/ubuntu) otherwise), therefore the selected Ubuntu version must be between the supported tags.
        * **`python_version`**: The Python version to be installed in the docker image.
        * **`sections_to_remove`**: The sections to be removed from the ZeroCost style notebook (must be separated by spaces and follow the X.X. format). In case you want to keep all the sections, you can leave this argument empty, but you still need to define it.
        * **description`**: A brief description of the notebook specified in the `notebook_url`. This description needs to be in a single line to be shown by the GUI. You can also leave this argument empty, but is recommended to give even a small description.
        * **`notebook_version`**: The version of the notebook specified in the `notebook_url`. In the cases from [ZeroCostDL4Mic notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) the notebook version is taken from the [ZeroCostDL4Mic GitHub repository](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master).
        * <span style="color:white"> *[optional]*</span> **`dl4miceverywhere_version`**: The version of the DL4MicEverywhere repository that is going to be used to create the docker image. Normally, this argument will be automatically generated when the `configuration.yaml` file is added or modified, the version is taken from the [construct.yaml](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/construct.yaml) file. But in case you want to create and use your own configuration, this attribute is not needed (it only might affect during the creation of the docker image's tag).
        * <span style="color:white"> *[optional]*</span> **`docker_hub_image`**: This is the name of the docker image that will be created. This name will also be used to check if there is an existing image on the [DockerHub repository from henriqueslab](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere/general). Normally, this argument will be automatically generated when the `configuration.yaml` file is added or modified, the value is a combination of the notebook name, the `notebook_version` and the `dl4miceverywhere_version` (e.g. `care_2d_zerocostdl4mic-z1.15.2-d1.0.0`, being `care_2d_zerocostdl4mic` the name of the notebook, `z` indicating that is a ZeroCostDL4MicEverywhere notebook, `1.15.2` is the version of the notebook and `1.0.0` the version of the DL4MicEverywhere repository). But in case you want to create and use your own configuration, this attribute is not needed, the tag that will be generated from the available information on the `configuration.yaml` file.

For instance, here is the provided `configuration.yaml` file for the CARE 2D notebook:


```
config:
  dl4miceverywhere:
    notebook_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/CARE_2D_ZeroCostDL4Mic.ipynb
    requirements_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/requirements_files/CARE_2D_requirements_simple.txt
    cuda_version: 11.8.0
    ubuntu_version: '22.04'
    python_version: '3.10'
    sections_to_remove: 1.1. 1.2. 2. 6.3.
    description: CARE_2D_DL4Mic is the conversion of the 2D CARE from ZeroCostDL4Mic. 
    notebook_version: 1.15.2
    dl4miceverywhere_version: 1.0.0
    docker_hub_image: care_2d_zerocostdl4mic-z1.15.2-d1.0.0

```
