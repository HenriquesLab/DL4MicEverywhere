# DL4MicEverywhere

Welcome to **DL4ME**!

Home of the docker image creator that allows **YOU** to run the amazing [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) notebooks on your own computer without having to install all those pesky requirements and libraries by yourself!

## Getting Started


- Download and install the appropriate version of [Docker Desktop](https://www.docker.com/products/docker-desktop/) for your operating system.
- Download the [Dockerfile](Dockerfile) and the [launch.sh](launch.sh) files
- Have a local **configuration.yaml** for the relevant notebook 
    - Download one from [notebooks](./notebooks) for [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) supported notebooks
    - Create your own configuration.yaml for ZeroCostDL4Mic type notebooks by following the guidelines (tbd)
- Have your data on disk


**Optional**
- Local copy of the **.ipynb** notebook file
- Local copy of the **requirements.txt** file

## Run using GUI
Currently the use of a graphical user interface (GUI) still requires some use of the terminal or command line interface (CLI).


### Linux
WIP

### MacOSX

The use of this GUI requires installing [**zenity**](https://formulae.brew.sh/formula/zenity#default) via [**Homebrew**](https://brew.sh/).

To launch the GUI run this on the terminal using the absolute path to the **launch.sh** file.
``` bash
 sudo bash /Path/to/launch.sh -i
```

### Windows
WIP


## Run using CLI

### Linux
WIP

### MacOSX
We recommend the use of absolute paths for the files, as relative paths might not always work.
```bash
sudo bash /Path/to/launch.sh -d /Path/to/datasetFolder -c /Path/to/configuration.yaml
```
Optional arguments:
```bash
-g #use GPU
-n /Path/to/notebook.ipynb #Path to local notebook.ipynb
-r /Path/to/requirements.txt #Path to local requirements.txt
-t docker-image-name #Name of the docker image
```
### Windows
WIP



