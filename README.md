# DL4MicEverywhere

Welcome to **DL4ME**!

Home of the docker image creator that allows **YOU** to run the amazing [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) notebooks on your own computer without having to install all those pesky requirements and libraries by yourself!

## Getting Started


- Download and install the appropriate version of [Docker Desktop](https://www.docker.com/products/docker-desktop/) for your operating system.
- Have a local **configuration.yaml** for the relevant notebook 
    - Download one from [notebooks](./notebooks) for [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) supported notebooks
    - Create your own following the guidelines for other Google Collab notebooks (tbd)
- Have your data available locally (?)
- download this repo/ the docker file + lauch.sh / eventually an executable?

**Optional**
- Local copy of the **.ipynb** notebook file
- Local copy of the **requirements.txt** file

## Run using GUI

still requires using the command line at the time
### MacOSX
Make sure the cwd (current working directory) is where the launch.sh file is
``` bash
 sudo bash ./launch.sh -x zenity
```

### Windows
wip

### Linux
wip

## Run using CLI

### MacOSX
Make sure the cwd (current working directory) is where the launch.sh file is
```bash
sudo bash ./launch.sh -d ./datasets/care2d -c ./notebooks/CARE_2D_DL4Mic/configuration.yaml
```
### Windows
wip

### Linux
wip


