# Docker Desktop Overview

Docker Desktop is a tool for managing Docker containers and images. It provides a visual interface for monitoring the Docker images installed on your computer and the containers currently running.

> ℹ️ This page applies to **Windows and macOS**. On Linux, DL4MicEverywhere uses Docker Engine (Docker Desktop for Linux cannot use NVIDIA GPUs); see the Linux note in the [User Guide](USER_GUIDE.md#run-dl4miceverywhere-for-the-first-time).

## Keeping Docker Desktop up to date

Older Docker Desktop releases can fail to pass the NVIDIA GPU through to WSL 2 with newer NVIDIA libraries. Update from Docker Desktop itself (**Check for updates**); per-user installations update without Administrator rights. When an NVIDIA GPU is present and the installed version is older than the tested minimum, `Windows_launch.bat` shows a warning and lets you continue or stop. It never updates Docker Desktop automatically.


## Windows per-user installation

On current Windows versions, Docker Desktop supports a per-user installation under `%LOCALAPPDATA%\Programs\DockerDesktop`. Docker documents this as the recommended mode for most users; it does not require Windows Administrator privileges and uses the WSL 2 backend for Linux containers.

When `Windows_launch.bat` finds a working WSL 2/Ubuntu setup but no Docker Desktop installation, DL4MicEverywhere can offer this installation automatically. The launcher requires explicit acceptance of Docker's Subscription Service Agreement, downloads the installer from Docker's official HTTPS endpoint, verifies its Windows Authenticode signature, and installs with the WSL 2 backend and Windows containers disabled. DL4MicEverywhere does not elevate itself and does not modify Docker Desktop's WSL-integration settings file.

Enabling WSL 2 for the first time remains a Windows machine-level prerequisite and may require Administrator privileges. If WSL is missing or outdated, the launcher stops and gives the corresponding Windows setup command before attempting Docker installation.

## Cleaning Docker Containers and Images

Docker images typically occupy between 3 - 5 GB of memory. Therefore, it's advisable to periodically review and remove any unnecessary images. To do this, first check if any container is using the image. If so, stop and remove it by clicking on the bin symbol. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_CONTAINER.png" 
     alt="Docker desktop container"
     width="50%" 
     height="50%" />

Next, navigate to Images and remove any images that are no longer needed.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DOCKER_DESKTOP_IMAGE.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />

To display all the container images currently occupying space on your computer, use:

`docker images`

To remove all unused images, use:

`docker image prune -a`

To remove all unused containers, networks, and images, use:

`docker system prune -a`


## Managing Docker

You can pause, restart, or close Docker by clicking on the Docker shortcut symbol: 
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/STOP_DOCKER.png" 
     alt="Docker desktop images"
     width="50%" 
     height="50%" />
