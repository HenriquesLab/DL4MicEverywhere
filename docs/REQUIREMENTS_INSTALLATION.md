# DL4MicEverywhere Requirements Installation Guidelines

You can double-click the launcher in the DL4MicEverywhere folder (which has the same name as your system, e.g., Windows_launch for Windows operating systems) to launch the GUI, but it also does some requirements checking. At the beginning of the process, the launcher checks if the requirements listed below are installed; otherwise, they are installed automatically. On Debian/Ubuntu systems, DL4MicEverywhere installs only the missing packages it needs; it does not perform a full operating-system upgrade as part of application setup. It can happen that the installation is not successfully done; in that case, please follow the guidelines provided on this page.

### Requirements

- Docker installed on your system.
- Python 3 with `venv` support when a missing/stale dependency lock must be generated for a local image build. DL4MicEverywhere installs this host-side helper automatically when needed.
- For GPU usage - NVIDIA GPU + CUDA drivers.
- If you want to run the graphical user interface (GUI), [Tcl/Tk](https://www.tcl.tk/) must be installed on your computer. 

The installation guidelines will be different depending on your operative system. Select the operative system on you computer and follow the indicated steps:

<details>
<summary>On Windows:</summary>

## Intro
Windows operating systems require a slightly more complicated installation process. Also, beware there might be differences between Windows 10 and 11.
- Install/enable WSL 2 and Ubuntu.
- Docker Desktop can then be installed automatically by DL4MicEverywhere in per-user mode, or installed manually if preferred. 
- Install TCL/TK in WSL's Ubuntu.

## Requirements
- WSL (Windows Subsystem for Linux) - Pre-installed on most Windows 10/11 systems, otherwise it is available on the Microsoft store.
- Install and/or update all the GPU [NVIDIA drivers](https://www.nvidia.com/download/index.aspx), [cudatoolkit](https://developer.nvidia.com/cuda-toolkit), and [cuDNN](https://developer.nvidia.com/cudnn) necessary for your GPU.  

## 1. WSL 2 prerequisite and Docker Desktop installation

DL4MicEverywhere uses Docker Desktop's WSL 2 backend on Windows. Current Docker Desktop versions support a **per-user installation** to `%LOCALAPPDATA%\Programs\DockerDesktop`, which does not require Windows Administrator privileges. The `Windows_launch.bat` launcher offers this installation automatically when Docker Desktop is missing.

The launcher deliberately checks WSL first because enabling WSL 2 for the first time is a Windows machine-level operation that may require Administrator privileges. Docker Desktop currently requires WSL 2.1.5 or later. Once WSL 2 and Ubuntu are available, the automatic Docker path is:

1. Ask for explicit acceptance of Docker's Subscription Service Agreement.
2. Download Docker Desktop from Docker's official HTTPS endpoint.
3. Validate the downloaded installer's Windows Authenticode signature and Docker signer identity.
4. Install Docker Desktop with Docker's `--user --backend=wsl-2 --no-windows-containers` options.
5. Start Docker Desktop and wait for the Docker engine.
6. Verify Docker directly from the selected Ubuntu WSL 2 distribution.

If you prefer to install Docker Desktop manually, follow Docker's official Windows instructions: https://docs.docker.com/desktop/setup/install/windows-install/ and choose the WSL 2 backend.

## 2. Setup the WSL (Windows Subsystem for Linux)

### 2.1. Install Ubuntu inside WSL
Open a Command Line (cmd.exe) or PowerShell window and run:
 
```
wsl --install -d Ubuntu
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
wsl sudo apt-get update
```
```
wsl sudo apt-get install -y tcl tk
```

Now TCL/TK should be installed inside WSL's Ubuntu.

To check if TCL/TK is correctly installed run:
```
wsl wish
```
This should open a new window named Wish. If it fails repeat the previous steps again or create a [Issue](https://github.com/HenriquesLab/DL4MicEverywhere/issues/new/choose) letting us know your problem. 

</details>

<details>
<summary>On Linux:</summary>

## 1. Docker Installation

Firstly, Docker Desktop needs to be installed on your computer. Follow the official guideline: https://docs.docker.com/desktop/install/linux-install/

## 2. Install Tcl/Tk for the DL4MicEverywhere graphical user interface

The only requirement to use the graphical user interface (GUI) is to have [Tcl/Tk](https://www.tcl.tk/) installed on your computer. 

Most Unix / Linux operating system distributions include Tcl and Tk. If not already installed, use your system's package manager to install the appropriate packages. For Ubuntu, use the following commands:

```
sudo apt-get update
sudo apt-get install -y tcl tk
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
   Install or update the `tcl-tk` package:
   ```
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

### Restart after prerequisite installation

When DL4MicEverywhere installs missing host prerequisites, it may recommend a restart before continuing. On Windows/WSL, **Restart Now** requests a restart of the Windows host (not only the WSL distribution), while **Restart Later** exits the launcher cleanly so Windows can be restarted manually. Neither choice is treated as an installation failure.
