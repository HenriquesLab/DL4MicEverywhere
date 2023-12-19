# DL4MicEverywhere User Guide

DL4MicEverywhere is a user-friendly platform that allows you to run deep learning notebooks for microscopy imaging analysis on your local machine or remote infrastructure. This guide will walk you through the steps to get started.

## Installation

### Requirements

Before you can use DL4MicEverywhere, ensure you have the following:

- Docker installed on your system 
- For GPU usage - NVIDIA GPU + CUDA drivers
- If you want to run the graphical user interface (GUI), [Tcl/Tk](https://www.tcl.tk/) must be installed on your computer. 

In case you miss some of the requirements, follow the steps descibed on the [REQUIREMENTS INSTALLATION](REQUIREMENTS_INSTALLATION.md).

### Download DL4MicEverywhere Repository:

* **Option 1**: Download the ZIP file from GitHub's repository

    1. Download a ZIP file of the DL4MicEverywhere repository by clicking [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip).

    2. Decompress the downloaded file.

* **Option 2**: Download from the terminal using git

    > ⚠️: **IMPORTANT**:
    > `git` must be installed. If not, follow the [official installation steps](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

    > ℹ️ **NOTE**:
    > You need to be located in the folder where you want to download the DL4MicEverywhere repository.

    ```
    git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
    ```

### Navigate to the repository directory:

```
cd DL4MicEverywhere
```

That's it for installation! Docker wraps up all the dependencies needed to run the notebooks.

## Quickstart 

> ⚠️: **IMPORTANT:**
> The GPU usage on Windows machines is not working at this moment due to some TensorFlow and NVIDIA compatibility issues. This issue is under development (alternatives like conda are considered [here](https://github.com/HenriquesLab/DL4MicEverywhere/tree/Pass-to-conda)) and discussed [here](https://github.com/HenriquesLab/DL4MicEverywhere/issues/24). 

**Launch the notebook selection GUI:**

> ℹ️ **NOTE**:
    > You need to be located in the DL4MicEverywhere folder, where the file launch.sh is in.

```
sudo -E bash ./launch.sh
```

This command will open a GUI window where you can choose a notebook. 

**Select a notebook:**

Select one of the available notebooks, such as U-Net 2D or StarDist 3D. This will populate the description on the right.

**Specify data and output folders:** 

Use the GUI to select the folder containing your input data and the folder where you want to save results. 

**Click "Run" to launch the notebook:**

This action will build a Docker container for the selected notebook and then start it. Follow the prompts to access the Jupyter interface through your web browser.

Now, you're ready to run deep learning workflows through an intuitive UI!


# Step-by-step user guide

For a more detailed guide, please follow the installation guidelines [here](REQUIREMENTS_INSTALLATION.md).

## 1. Launch the Docker Desktop application

The Docker Desktop application must be running while using DL4MicEverywhere. To start it, open the recently installed Docker Desktop application. After agreeing to the terms, you should see a window like this:

![Docker desktop application](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Docker_desktop.png)

## 2. Launch DL4MicEverywhere

### 2.1 - Open a terminal in the downloaded DL4MicEverywhere folder
Below are screenshots showing how to open a terminal in different operating systems.

<details>
<summary>On Windows:</summary>

In the downloaded DL4MicEverywhere folder, right-click an empty area of the folder. Then, among the options, you will find **Open the terminal** as shown in the picture below:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Windows.png" 
     alt="Screenshot launching the terminal on Windows"
     width="60%" 
     height="60%" />

</details>

<details>
<summary>On Linux:</summary>

In the downloaded DL4MicEverywhere folder, right-click an empty area of the folder. Then, among the options, you will find **Open in Terminal** as shown in the picture below:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Linux.png" 
     alt="Screenshot launching the terminal on Windows"
     width="60%" 
     height="60%" />

</details>

<details>
<summary>On Mac:</summary>

Right-click the DL4MicEverywhere folder. Among the options, choose **New Terminal at Folder** as shown in the capture below:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Mac.png" 
     alt="Screenshot launching the terminal on Mac"
     width="40%" 
     height="40%"/>

</details>


### 2.2 - Launch the main program
DL4MicEverywhere is started from the terminal using `launch.sh`. There are two ways to work with it:

* **Option 1**: [Launch it with the graphical user interface (GUI)](GUI_USER_GUIDE.md)
* **Option 2**: [Launch it with the command line interface (CLI)](CLI_USER_GUIDE.md)

## 3. Docker images

DL4MicEverywhere will either pull a container image from Dockerhub or build one for you if there isn't one suitable for your operating system and configuration. The interface may ask you 

1. if there is already an image on your machine, would you like to rebuild and replace it?
2. if there is no image on your machine but there is one on the Docker hub, would you like to build it?
   
While building or pulling the image, your terminal window will look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/IMAGE_BUILD_TERMINAL.png" 
     alt="Terminal after building a docker image"
     width="60%" 
     height="60%" />

     
Docker images occupy between 3 and 5 GB of memory, so it is advisable to manage them periodically. Check how to do it [here](DOCKER_DESKTOP.md)

## 4. Run Jupyter Lab

After building a Docker image and running a container to run the notebooks, DL4MicEverywhere will automatically run Jupyter Lab in the terminal. You need to copy the link and paste it in your preferred browser as follows:
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTER_TOKEN_TERMINAL.png" 
     alt="Terminal after running Jupyter Lab"
     width="60%" 
     height="60%" />
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/LAUNCH_JUPYTER.png" 
     alt="Opening Jupyter Lab in the browser"
     width="60%" 
     height="60%" />

At the end of this process, you should see a window similar to this one in your browser. On the right column, you will see a Data and Results folder, as well as the notebook you chose to open.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTERLAB.png" 
     alt="Jupyter Lab in the browser"
     width="60%" 
     height="60%" />

## 5. Work with DL4MicEverywhere notebooks

The notebooks, inspired by ZeroCostDL4Mic, are designed to be user-friendly and do not require programming skills to run them. When you open the notebook in Jupyter Lab, code cells are hidden with a message `# Run this cell to visualise the parameters and click the button to execute the code ...`. 

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
