# DL4MicEverywhere Design

## Introduction

DL4MicEverywhere is an initiative designed to enhance the flexibility, shareability, and reproducibility of deep learning for microscopy. It extends the capabilities of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by offering a Docker-based backend that enables users to execute ZeroCostDL4Mic notebooks either locally or on remote infrastructure, eliminating the dependency on Google Colab.

The system comprises the following key components:

- Individual Docker containers for each ZeroCostDL4Mic notebook.
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

At the heart of DL4MicEverywhere are Docker containers, each corresponding to a notebook (see [notebook types](NOTEBOOK_TYPES.md)). These containers package all the necessary dependencies and configurations required for the smooth operation of the notebooks, thereby enhancing reproducibility by mitigating software environment discrepancies.

The `Dockerfile` outlines the base image, installs dependencies, duplicates the notebook and requirements files, and sets up commands to execute the notebook. Build arguments are used to populate dynamic values based on the notebook configuration.

GitHub Actions are set up to automatically build and publish these containers to DockerHub whenever changes are made.

## Launch Script and GUI

The `launch.sh` script offers a straightforward interface for building and running the Docker containers. It manages argument parsing, configuration file reading, pre-build testing, image building, and container execution.

The GUI, implemented in `gui.tcl`, provides an interactive method for selecting notebooks and parameters. It offers options for basic or advanced configuration. The GUI utilizes the `launch.sh` script to manage the build/run process.

## Configuration Files

Each notebook is associated with a `configuration.yaml` file that specifies:

- The Notebook URL.
- The Requirements URL.
- Software versions (CUDA, Ubuntu, Python).
- Sections to be removed during the Colab -> Jupyter conversion.
- Metadata such as name, version, description.
See [configuration file format](FORMAT.md) for details.

The launch scripts utilize these configurations to determine the build process for the containers.

## Automated Building 

GitHub Actions workflows, defined in `.github/workflows/`, manage the automatic building and testing of containers upon changes.

The `build_docker_images_.yml` workflow builds containers and pushes them to DockerHub when changes are made to configurations or the core build scripts.

## Jupyter Notebooks

The ZeroCostDL4Mic notebooks are converted from Colab to Jupyter format using a custom script. Jupyter notebooks maintain the original interactivity through the use of ipywidgets, providing a consistent and user-friendly interface.
