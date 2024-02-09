# Format of YAML Configuration Files for DL4MicEverywhere

DL4MicEverywhere follows the [standards](https://bioimage.io/docs/#/bioimageio_model_spec) of the [BioImage Model Zoo](https://bioimage.io/#/). 

Each notebook is described using a `configuration.yaml` file with the metadata of the notebook as well as the parameters required for Docker container creation. A [collection of configuration files](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks) for different versioned notebooks is already available. This collection is also versioned and tested through continuous integration pipelines. The users have also the flexibility to create and use their own configurations locally for their notebooks. 

The structure of these YAML file is the same as in the BioImage Model Zoo with an additional field inside the `config` field:

* **`config`**:
    * **`dl4miceveryhwere`**:
        * **`notebook_url`**: The URL to the Jupyter notebook that is stored in the Docker image.
        * **`requirements_url`**: The URL Python dependencies that are installed in the Docker image.
        * **`cuda_version`**: The CUDA version in the Docker image. The CUDA version is used to pull the Ubuntu image from Docker Hub (from [Nvidia](https://hub.docker.com/r/nvidia/dcgm-exporter) if GPU is selected). Its version (and the `ubuntu_version`) should be one from the following [list](https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md).
        * **`ubuntu_version`**: The Ubuntu version for the operating system in the Docker image. This version is used to pull the base image from Docker Hub (from [Nvidia](https://hub.docker.com/r/nvidia/dcgm-exporter) if GPU is selected and from [Ubuntu](https://hub.docker.com/_/ubuntu) otherwise). The selected Ubuntu version must be between among the supported tags.
        * **`python_version`**: The installed Python version in the docker image.
        * **`sections_to_remove`**: The sections from the ZeroCostDL4Mic style notebook that are removed. Must be separated by spaces and follow the X.X. format. To keep all the sections, leave this argument empty; you still need to declare it.
        * **`description`**: A single-line description of the notebook that is shown in the GUI.
        * **`notebook_version`**: The version of the notebook in `notebook_url`. For [ZeroCostDL4Mic notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) the version is taken from the [ZeroCostDL4Mic GitHub repository](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master).
        * <span style="color:white"> *[optional]*</span> **`dl4miceverywhere_version`**: The DL4MicEverywhere version. Normally, this argument will be automatically generated when the `configuration.yaml` file is added or modified. The version is taken from the [construct.yaml](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/construct.yaml) file. But in case you want to create and use your own configuration, this attribute is not needed (it can impact the tag of the Docker image).
        * <span style="color:white"> *[optional]*</span> **`docker_hub_image`**: The name of the created Docker image. This name is used to check if there is an existing image on the [DockerHub repository from henriqueslab](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere/general). Normally, this argument ise automatically generated when the `configuration.yaml` file is added or modified. The value is a combination of the notebook name, the `notebook_version` and the `dl4miceverywhere_version` (e.g. `care_2d_zerocostdl4mic-z1.15.2-d1.0.0`, being `care_2d_zerocostdl4mic` the name of the notebook, `z` indicating that is a ZeroCostDL4MicEverywhere notebook, `1.15.2` is the version of the notebook and `1.0.0` the version of the DL4MicEverywhere repository). If you want to create and use your configuration, this attribute is not needed. The tag will be generated from the available information on the `configuration.yaml` file.

As an example, here is the specific DL4MicEverywhere `config` field for the `configuration.yaml` file of CARE 2D notebook:

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
Find the complete file [here](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/ZeroCostDL4Mic_notebooks/CARE_2D_DL4Mic/configuration.yaml). 
