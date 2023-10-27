# DL4MicEverywhere Design

## Overview

DL4MicEverywhere is a project that aims to make deep learning for microscopy more flexible, shareable and reproducible. It builds on [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by providing a standalone Docker-based backend that allows users to run the ZeroCostDL4Mic notebooks locally or on remote infrastructure instead of relying on Google Colab.

The key components of the system are:

- Docker containers for each ZeroCostDL4Mic notebook 
- Launch script and GUI to build and run containers
- Automated testing and building using GitHub Actions
- Configuration files to specify notebook details
- Jupyter Notebooks with ipywidgets for interactivity 

## Docker Containers

The core of DL4MicEverywhere is a Docker container for each existing ZeroCostDL4Mic notebook. These containers encapsulate all the dependencies and configurations required to run the notebooks properly. This encapsulation enhances reproducibility by eliminating inconsistencies due to software environment differences.

The `Dockerfile` specifies the base image, installs dependencies, copies the notebook and requirements files, and sets up commands to run the notebook. Build arguments populate dynamic values based on the notebook configuration.

GitHub Actions automatically builds and publishes these containers to DockerHub on changes.

## Launch Script and GUI

The `launch.sh` script provides a simple interface to build and run the Docker containers. It handles parsing arguments, reading the configuration file, executing pre-build tests, building the image, and running the container.

The GUI implemented in `gui.tcl` gives an interactive way to select notebooks and parameters. It provides options for basic or advanced configuration. The GUI calls the `launch.sh` script under the hood to handle the build/run process.

## Configuration Files

Each notebook has a `configuration.yaml` file that specifies:

- Notebook URL
- Requirements URL
- Software versions (CUDA, Ubuntu, Python)
- Sections to remove during Colab -> Jupyter conversion
- Metadata like name, version, description

The launch scripts read these configurations to determine how to build the containers.

## Automated Building 

GitHub Actions workflows defined in `.github/workflows/` handle automatically building and testing containers on changes.

The `build-and-deploy.yml` workflow builds containers and pushes them to DockerHub on changes to configurations or the core build scripts.

The `NotebookUpdateChecker.yml` workflow runs daily to check for notebook updates and trigger rebuilds if new versions are found.

Unit tests in `tests/` validate build scripts are functioning properly.

## Jupyter Notebooks

The ZeroCostDL4Mic notebooks are converted from Colab to Jupyter format using a custom script. Jupyter notebooks retain the original interactivity through ipywidgets. This provides a consistent and familiar interface for users.
