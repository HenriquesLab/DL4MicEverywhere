# DL4MicEverywhere User Guide

DL4MicEverywhere provides an easy way to run deep learning notebooks for microscopy analysis on your local machine or remote infrastructure. This guide covers the steps to get started.

## Installation

To use DL4MicEverywhere, you need:

- Docker installed on your system 
- For GPU usage - NVIDIA GPU + CUDA drivers
- If you want to run the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/) has to be installed on your computer. Check further instructions [here](docs/GUI_USER_GUIDE.md).

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

# Step-by-step documentation

## 1. Install the requirements

First of all you will need to install Docker Desktop on your computer. You can follow the official provided guidelines based on your operative system:

* Windows: https://docs.docker.com/desktop/install/windows-install/
* Linux: https://docs.docker.com/desktop/install/linux-install/
* Mac: https://docs.docker.com/desktop/install/mac-install/

## 2. Download the DL4MicEverywhere repository

* **Option 1**: Download the ZIP file from GitHub's repository

    1.- Download a ZIP file with the DL4MicEverywhere repository by clicking [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip).

    2.- Decompress the downloaded file.

* **Option 2**: Download from the terminal using git

    > ❗**IMPORTANT**:
    > You need to have `git` installed. If you do not have, follow the [official installation steps](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

    > ℹ️ **NOTE**:
    > You need to be located in the folder where you want to download the DL4MicEverywhere repository.

    ```
    git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
    ```

## 3. Launch the Docker Desktop application

Open the application installed on first step, you will be asked different agreements and at the end you should arrive to a window like this:

![Docker desktop application](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/Docker_desktop.png)

## 4. Launch DL4MicEverywhere

### 4.1 - Open a terminal in the downloaded DL4MicEverywhere folder
Below there are screenshots in each operative system in case you need a hint to open the terminal.

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


### 4.2 - Launch the main program
Once that you have open the terminal, you will need to use it in order to execute the main program that is on `launch.sh`. To introduce the input argument to the program you have to choose between these two different options:

* **Option 1**: [Launch it with the graphical user interface (GUI)](docs/GUI_USER_GUIDE.md)
* **Option 2**: [Launch it with the command line interface (CLI)](docs/CLI_USER_GUIDE.md)
