# DL4MicEverywhere User Guide

DL4MicEverywhere is a user-friendly platform that allows you to run deep learning notebooks for microscopy imaging analysis on your local machine or remote infrastructure. This guide will walk you through the steps to get started.

## Installation

### Download DL4MicEverywhere Repository:

* **Option 1**: Download the last version of DL4MicEverywhere from GitHub's repository:

    1. Download a ZIP file of the DL4MicEverywhere repository by clicking [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip).

    2. Unzip the downloaded file and go to the DL4MicEverywhere folder. 

* **Option 2**: Download from the terminal using git:

    > ⚠️: **IMPORTANT**:
    > `git` must be installed. If not, follow the [official installation steps](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

    > ℹ️ **NOTE**:
    > You need to be located in the folder where you want to download the DL4MicEverywhere repository.

    ```
    git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
    cd DL4MicEverywhere
    ```

### Run DL4MicEverywhere for the first time:
DL4MicEverywhere comes packaged with an executable for each operating system. Double-click on the one that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). To run DL4MicEverywhere for the first time you need to have root/admin permissions as the program will check for the presence of the requirements and will attempt to install any that are missing. If it encounters an issue during the automatic installation of the requirements, the [REQUIREMENTS INSTALLATION](REQUIREMENTS_INSTALLATION.md) page has detailed information about the requirements and intructions on how to manually install them.
Once the process has finished, the computer needs to be restarted.
This is a single process the first time that DL4MicEverywhere is launched. 

## Quickstart 

> ⚠️: **IMPORTANT:**
> The GPU usage on Windows 10 machines is not working at this moment due to some TensorFlow and NVIDIA compatibility issues. This issue is under development (alternatives like conda are considered [here](https://github.com/HenriquesLab/DL4MicEverywhere/tree/Pass-to-conda)) and discussed [here](https://github.com/HenriquesLab/DL4MicEverywhere/issues/24). 

**Launch the notebook selection GUI:**

Double-click the launcher in the DL4MicEverywhere folder that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). A GUI will automatically pop-up.

**Select a notebook:**

- Select one of the available notebooks, such as U-Net 2D or StarDist 3D. This will populate the description on the right.

**Specify data and output folders:** 

- Use the GUI to select the folder containing your input data and the folder where you want to save results. 

**Click "Run" to launch the notebook:**

- This action will build a Docker container for the selected notebook and then start it. Follow the prompts to access the Jupyter interface through your web browser.

Now, you're ready to run deep learning workflows through an intuitive UI!


# Step-by-step user guide


## 1. Launch DL4MicEverywhere

Double-click the launcher in the DL4MicEverywhere folder that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). A GUI will automatically pop-up.

## 2. Docker images

DL4MicEverywhere will either pull a container image from Dockerhub or build one for you if there isn't one suitable for your operating system and configuration. The interface may ask you:

1. if there is already an image on your machine, would you like to rebuild and replace it?
2. if there is no image on your machine but there is one on the Docker hub, would you like to build it?
   
While building or pulling the image, your terminal window will look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/IMAGE_BUILD_TERMINAL.png" 
     alt="Terminal after building a docker image"
     width="60%" 
     height="60%" />

Docker images occupy between 3 and 5 GB of memory, so it is advisable to manage them periodically. Check how to do it [here](DOCKER_DESKTOP.md)

## 3. Work with DL4MicEverywhere notebooks
After building a Docker image and running a container to run the notebooks, DL4MicEverywhere will automatically run Jupyter Lab and open it in the default browser.
The notebooks, inspired by ZeroCostDL4Mic, are designed to be user-friendly and do not require programming skills to run them. Follow their [Step-by-step "How to"](https://github.com/HenriquesLab/ZeroCostDL4Mic/wiki/Step-by-step-run-through) to get further details about parameters and data formats. 

When you open the notebook in Jupyter Lab, code cells are hidden with a message `# Run this cell to visualise the parameters and click the button to execute the code ...`. 

When you run the code cells (either by pressing `Ctrl+Enter` or clicking on the play symbol on the top bar of the notebook), an interactive menu appears as shown in the image. In this menu, you can specify any required parameter. After specifying all the parameters, click on "Load and run". Note that if you do not click, the code of that cell will not run. Likewise, if you run the cell again, the parameters will need to be specified again. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/NOTEBOOK_PARAMS.png" 
     alt="Notebook parameters"
     width="100%" 
     height="100%" />

**IMPORTANT**: 
- Docker is running on a virtual machine, so the main path is `/home/` and anything shown on the left directory, is placed inside `/home/`. This means that when we want to provide the path to `data` in the code, we need to indicate it as `"/home/data"`.
- Anything stored outside of the `Data` and `Results` folder will disappear when stopping the docker container or closing the terminal. Thus, anything you want to save, including the notebook, needs to be placed in the Results folder. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTERLAB_DIR.png" 
     alt="Jupyter Lab home directory"
     width="60%" 
     height="60%" />
