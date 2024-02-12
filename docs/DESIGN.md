# DL4MicEverywhere Design

## Introduction

DL4MicEverywhere is an initiative designed to enhance the flexibility, shareability, and reproducibility of deep learning for microscopy. It extends the capabilities of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by offering a Docker-based backend that enables users to execute ZeroCostDL4Mic notebooks either locally or on remote infrastructure, eliminating the dependency on Google Colab.

The system comprises the following key components:

- Individual Docker images for each ZeroCostDL4Mic notebook.
- A launch script and GUI for building and executing containers.
- GitHub Actions for automated testing and building.
- Configuration files detailing notebook specifics.
- Interactive Jupyter Notebooks with ipywidgets.

## General requirements

Before you can use DL4MicEverywhere, ensure you have the following:

- Docker installed on your system.
- For GPU usage - NVIDIA GPU + CUDA drivers.
- If you want to run the graphical user interface (GUI), [Tcl/Tk](https://www.tcl.tk/) must be installed on your computer. 

In case you miss some of the requirements, follow the steps described on the [REQUIREMENTS INSTALLATION](REQUIREMENTS_INSTALLATION.md).

## Docker Containers

At the heart of DL4MicEverywhere are Docker images, each corresponding to a notebook (see [notebook types](NOTEBOOK_TYPES.md)). These images package all the necessary dependencies and configurations required for the smooth operation of the notebooks, thereby enhancing reproducibility by mitigating software environment discrepancies.

Both [`Dockerfile`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Dockerfile) and [`Dockerfile.gpu`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Dockerfile.gpu) outline the base images, install dependencies (the GPU dependencies in case of the second one), duplicate the notebook and requirements files, and set up commands to execute the notebook. Build arguments are used to populate dynamic values based on the notebook configuration.

GitHub Actions are set up to automatically build and publish these containers to DockerHub whenever changes are made.

## Launch Script and GUI

Three different launchers are provided, one for each operative system:

- [`MacOS_launch.sh`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/MacOS_launch.sh): which is a double click launcher for MacOS systems. You might get a message saying 'cannot be oppened because it is from an unidentified developer', if that is the case, right click `MacOS_launch.sh` and select `Open` option, what will launch a similar message but know with an `Open` option.
- [`Windows_launch.sh`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Windows_launch.sh)
- [`Linux_launch.sh`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Linux_launch.sh)

The [`Linux_launch.sh`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Linux_launch.sh) script offers a straightforward interface for building and running the Docker containers. It manages argument parsing, configuration file reading, pre-build testing, image building, and container execution.

The GUI, implemented in [`main_gui.tcl`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/tcl_tools/main_gui.tcl), provides an interactive method for selecting notebooks and parameters. It offers options for basic or advanced configuration. The GUI utilizes the [`Linux_launch.sh`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/Linux_launch.sh) script to manage the build/run process.

## Configuration Files

Each notebook is associated with a `configuration.yaml` file that specifies:

- The Notebook URL.
- The Requirements URL.
- Software versions (CUDA, cuDNN, Ubuntu, Python).
- Sections to be removed during the Colab -> Jupyter conversion.
- Metadata such as name, version, description.
See [configuration file format](FORMAT.md) for details.

The launch scripts utilize these configurations to determine the build process for the containers.

## Automated Building 

GitHub Actions workflows, defined in `.github/workflows/`, manage the automatic building and testing of containers upon changes.

The workflows `build_all_images.yml`, `build_docker_images_aux.yml`, `build_docker_images_new_config.yml` and `build_pushed_config.yaml` build containers and push them to [our DockerHub repository](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere/general) when changes are made to configurations or the core build scripts.

## Jupyter Notebooks

The ZeroCostDL4Mic notebooks are converted from Colab to Jupyter format using a [custom script](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/notebook_autoconversion/transform.py). Jupyter notebooks maintain the original interactivity through the use of ipywidgets, providing a consistent and user-friendly interface.
