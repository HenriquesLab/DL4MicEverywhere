# DL4MicEverywhere Requirements Installation Guidelines


### Requirements

- Docker installed on your system.
- For GPU usage - NVIDIA GPU + CUDA drivers.
- If you want to run the graphical user interface (GUI), [Tcl/Tk](https://www.tcl.tk/) must be installed on your computer. 

The installation guidelines will be different depending on your operative system. Select the operative system on you computer and follow the indicated steps:

<details>
<summary>On Windows:</summary>

## Intro
Windows operating systems require a slightly more complicated installation process. Also, beware there might be differences between Windows 10 and 11.
- Install Docker Desktop.
- Install Ubuntu inside WSL. 
- Install TCL/TK in WSL's Ubuntu.

## Requirements
- WSL (Windows Subsystem for Linux) - Pre-installed on most Windows 10/11 systems, otherwise it is available on the Microsoft store.
- Install and/or update all the GPU [NVIDIA drivers](https://www.nvidia.com/download/index.aspx), [cudatoolkit](https://developer.nvidia.com/cuda-toolkit), and [cuDNN](https://developer.nvidia.com/cudnn) necessary for your GPU.  

## 1. Docker Desktop installation
Firstly, Docker Desktop needs to be installed on your computer. Follow the official guidelines: https://docs.docker.com/desktop/install/mac-install/
 - During installation tick the recommended **WLS2** option.
 - To finalize the installation **Restart** the computer.

## 2. Setup the WSL (Windows Subsystem for Linux)

### 2.1. Install Ubuntu inside WSL
Open a Command Line (cmd.exe) or PowerShell window and run:
 
```
wsl --install
```
This will install Ubuntu inside WSL.

Once the installation ends it will ask for a username and a password. This is not necessary, exit the installation by using **Ctrl+C** or by closing the window.

Re-open the Command Line or PowerShell window and run the command **again**, if the installation was sucessfull you should see the following message:

![Ubuntu is sucessfully installed](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/WSL_UBUNTU_IS_INSTALLED.png)

### 2.2. Make Ubuntu the default configuration

Run the following command in the Command Line or PowerShell window to check what is the current default configuration.
```
wsl --list --verbose
```

The one with * is the default configuration. 

![Ubuntu is the default configuration](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/WSL_UBUNTU.png)

If it is not Ubuntu, it can be changed by using the command: 
```
wsl --set-default Ubuntu
```

### 2.3. TCL/TK installation 

TCL/TK is required for the graphical user interface (GUI) of DL4MicEverywhere, and it must be installed inside WSL's Ubuntu.

This requires running the following commands in the Command Line or PowerShell window:
```
wsl apt-get update
```
```
wsl apt-get install tk
```

Now TCL/TK should be installed inside WSL's Ubuntu.

To check if TCL/TK is correctly installed run:
```
wsl wish
```
This should open a new window named Wish. If it fails repeat the previous steps again.

</details>

<details>
<summary>On Linux:</summary>

## 1. Docker Installation

Firstly, Docker Desktop needs to be installed on your computer. Follow the official guideline: https://docs.docker.com/desktop/install/linux-install/

## 2. Install Tcl/Tk for the DL4MicEverywhere graphical user interface

The only requirement to use the graphical user interface (GUI) is to have [Tcl/Tk](https://www.tcl.tk/) installed on your computer. 

Most Unix / Linux operating system distributions include Tcl and Tk. If not already installed, use your system's package manager to install the appropriate packages. For Ubuntu, use the following commands:

```
sudo apt-get install tcl
sudo apt-get install tk
```

</details>

<details>
<summary>On Mac:</summary>

## 1. Docker Installation

Firstly, Docker Desktop needs to be installed on your computer. Follow the official guideline: https://docs.docker.com/desktop/install/mac-install/

## 2. Install Tcl/Tk for the DL4MicEverywhere graphical user interface

The only requirement to use the graphical user interface (GUI) is to have [Tcl/Tk](https://www.tcl.tk/) installed on your computer.

Most Mac OS X operating system distributions include Tcl/Tk. If not already installed, you will receive an error similar to the following:

```
DEPRECATION WARNING: The system version of Tk is deprecated and may be removed in a future release. Please don't rely on it. Set TK_SILENCE_DEPRECATION=1 to suppress this warning.
```
you can install or update the appropriate packages in two different ways:

 * Option 1: Using Homebrew:
   Reinstall your tcl-tk packages
   ```
   brew uninstall tcl-tk
   brew install tcl-tk
   ```

   **Note**: If you don't have the `brew` command, install [Homebrew](https://brew.sh/) by running the following command in your terminal:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

 * Option 2: Using a package installation:
   
   Go to https://www.tcl.tk/software/tcltk/ and click on the Active Tcl [link](https://www.activestate.com/products/tcl/): 

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_01.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   In this case, as you are using macOS, click on the macOS option:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_02_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Then, you can create an account, or continue to download without an account, to be able to download the installation file:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_03.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Afterwards this window will be shown. Don't worry. Click on **View all Available Builds**:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_04_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   and then click on the **Download** button to get the `.pkg` file:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_05_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Then, find the package that you have downloaded:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_06_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   and after double-clicking, an installation window will pop up. Click on **Continue** to start the installation:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_07_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   Click on **Continue** to go to the **License** step:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_08_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   Click on **Agree**:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_09_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   Click on **Install** to start the installation:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_10_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   The installation has been completed, click on **Close** and everything should be ready.

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_11_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

</details>

&nbsp;

Once you have followed all these steps, you are ready to run DL4MicEverywhere - the last step to continue is [downloading the DL4MicEverywhere repository](USER_GUIDE.md#download-dl4miceverywhere-repository) on the **User Guide**.
