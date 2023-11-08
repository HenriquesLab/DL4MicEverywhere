# DL4MicEverywhere Windows OS Installation Guide

## Intro
Windows operating systems require a slightly more complicated installation process. Also, beware there might be differences between Windows 10 and 11.
- Install Docker Desktop
- Install Ubuntu inside WSL 
- Install TCL/TK in WSL's Ubuntu

## Requirements
- WSL (Windows Subsystem for Linux) - Pre-installed on most Windows 10/11 systems, otherwise it is available on the Microsoft store.
- Install and/or update all the GPU [NVIDIA drivers](https://www.nvidia.com/download/index.aspx), [cudatoolkit](https://developer.nvidia.com/cuda-toolkit), and [cuDNN](https://developer.nvidia.com/cudnn) necessary for your GPU.



## 1. Docker Desktop installation
Download and install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/):
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

Then re-open the Command Line or PowerShell window and run the same command **again**, to ensure the installation was correct.

### 2.2. Make Ubuntu the default configuration

Run the following command in the Command Line or PowerShell window to check what is the current default configuration.
```
wsl --list -verbose
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
wsl apt-get install tk
```

Now TCL/TK should be installed inside WSL's Ubuntu.


## 3. DL4MicEverywhere Repository Download

* **Option 1**: Download the ZIP file from GitHub's repository

    1. Download a ZIP file of the DL4MicEverywhere repository by clicking [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip).

    2. Decompress the downloaded file.

* **Option 2**: Download from the terminal using git

    > ❗**IMPORTANT**:
    > `git` must be installed. If not, follow the [official installation steps](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

    > ℹ️ **NOTE**:
    > You need to be located in the folder where you want to download the DL4MicEverywhere repository.

    ```
    git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
    ```

This will create a folder called `DL4MicEverywhere` with all the files inside. You're now ready to run it - see the [User Guide](USER_GUIDE.md) for details.