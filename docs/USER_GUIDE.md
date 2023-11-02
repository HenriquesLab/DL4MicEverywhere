# DL4MicEverywhere User Guide

DL4MicEverywhere provides an easy way to run deep learning notebooks for microscopy analysis on your local machine or remote infrastructure. This guide covers the steps to get started.

## Installation

To use DL4MicEverywhere, you need:

- Docker installed on your system 
- For GPU usage - NVIDIA GPU + CUDA drivers
- If you want to run the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/) has to be installed on your computer. 

Check detailed installation guidelines [here](INSTALLATION.md).

**Clone the repo:**

```
git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
```

**Navigate to the repo directory:**

```
cd DL4MicEverywhere
```

That's it for installation! Docker wraps up all the dependencies needed to run the notebooks.

## Quickstart 

**Launch the notebook selection GUI:**

```
./launch.sh
```

This will open a GUI window to choose a notebook. 

**Select a notebook:**

Choose one of the listed notebooks like U-Net 2D or StarDist 3D. This will populate the description on the right.

**Specify data and output folders:** 

Use the GUI to select the folder with your input data and the folder to save results. 

**Click "Run" to launch the notebook:**

This will build a Docker container for the selected notebook and then start it. Follow the prompts to access the Jupyter interface through your web browser.

And you're ready to run deep learning workflows through an intuitive UI!


# Step-by-step user guide

Please, follow the installation guidelines [here](INSTALLATION.md).

## 1. Launch the Docker Desktop application

Docker Desktop application needs to be running while using DL4MicEverywhere. For this, open the recently installed Docker Desktop application. After checking on the agreement notes you should see a window like this:

![Docker desktop application](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Docker_desktop.png)

## 2. Launch DL4MicEverywhere

### 2.1 - Open a terminal in the downloaded DL4MicEverywhere folder
Check the screenshots below to see how to open a terminal in different operating systems.

<details>
<summary>On Windows:</summary>

Inside the downloaded folder from DL4MicEverywhere, you will need to right-click an empty are of the folder. Then, among those options you will find **Open the terminal** like in the picture below:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Windows.png" 
     alt="Screenshot launching the terminal on Windows"
     width="60%" 
     height="60%" />

</details>

<details>
<summary>On Linux:</summary>

Inside the downloaded folder from DL4MicEverywhere, you will need to right-click an empty are of the folder. Then, among those options you will find **Open in Terminal** like in the picture below:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Linux.png" 
     alt="Screenshot launching the terminal on Windows"
     width="60%" 
     height="60%" />

</details>

<details>
<summary>On Mac:</summary>

Located outside the DL4MicEverywhere folder, so you can right-click it. Among those option, you need to choose **New Terminal at Folder** like in the capture bellow:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Terminal_Mac.png" 
     alt="Screenshot launching the terminal on Mac"
     width="40%" 
     height="40%"/>

</details>


### 2.2 - Launch the main program
DL4MicEverywhere needs to be started from the terminal using `launch.sh`. There are two ways to work with it:

* **Option 1**: [Launch it with the graphical user interface (GUI)](GUI_USER_GUIDE.md)
* **Option 2**: [Launch it with the command line interface (CLI)](CLI_USER_GUIDE.md)

## 3. Docker images

DL4MicEverywhere will either pull a container image from Dockerhub or build one for you if there is not anyone suitable for your operating system and configuration. The interface may ask you 

1. if there is already an image in your machine, would you like to rebuild and replace it?
2. if there is no image in your machine but there exists one in the docker hub, would you like to build it?
   
While building or pulling the image, your terminal window will look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/IMAGE_BUILD_TERMINAL.png" 
     alt="Terminal after building a docker image"
     width="60%" 
     height="60%" />

     
Docker images occupy between 3 and 5 GB of memory, so it is convenient to take a look at them from time to time. Check how to do it [here](DOCKER_DESKTOP.md)

## 4. Run Jupyter Lab

After building the a Docker image and running a container to run the notebooks, DL4MicEverywhere will automatically run Jupyter Lab in the terminal. You need to copy the link and paste it in your favourite browser as follows:
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

The notebooks are inspired by ZeroCostDL4Mic and do not require programming skills to run them. When opening the notebook in Jupyter Lab, code cells are hidden with a message `# Run this cell to visualise the parameters and click the button to execute the code ...`. 

When running the code cells (either by pressing `Ctrl+Enter` or clicking on the play symbol on the top bar of the notebook), an interactive menu appears as shown in the image. In this menu you can specify any needed parameter. After specifying all the parameters, click on "Load and run". Note that if you do not click, the code of that cell will not run. Likewise, if you run the cell again, the parameters will need to be specified again. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/NOTEBOOK_PARAMS.png" 
     alt="Notebook parameters"
     width="100%" 
     height="100%" />

**IMPORTANT**: 
- Docker is running on a virtual machine, so the main path is `/home/` and anything shown on the left directory, is placed inside `/home/`. This means that when we want to provide the path to `data` in the code, we need to indicate it as `"/home/data"`.
- Anything stored out of the `Data` and `Results` folder will disappear when stopping the docker container or closing the terminal. Thus, anything you want to save, including the notebook, needs to be placed in the Results folder. 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTERLAB_DIR.png" 
     alt="Jupyter Lab home directory"
     width="60%" 
     height="60%" />
