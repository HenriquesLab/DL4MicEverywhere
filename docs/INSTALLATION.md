# DL4MicEverywhere installation guidelines

## 1. Install Docker

First of all, you need to install Docker Desktop on your computer. You can follow the officially provided guidelines based on your operative system:

* Windows: https://docs.docker.com/desktop/install/windows-install/
* Linux: https://docs.docker.com/desktop/install/linux-install/
* Mac: https://docs.docker.com/desktop/install/mac-install/

## 2. Install Tcl/Tk for the DL4MicEverywhere graphical user interface

The only requirement to use the graphical user interface (GUI) is to have [Tcl/Tk](https://www.tcl.tk/) installed on your computer. This can be accomplished in multiple way depending on your  operative system:

<details>
<summary>On Windows:</summary>

To install Tcl/Tk on your Windows computer, follow these steps:

First of all, got to https://www.tcl.tk/software/tcltk/ and click on the Active Tcl [link](https://www.activestate.com/products/tcl/): 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_01.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

In this case, as you are using Windows, click on the Windows option:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_02.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Then, you can create an account, or continue to download without an account, to be able to download the installation file:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_03.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Now you will need to download the Windows executable:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_04.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Find where your executable has been downloaded:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_05.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

and after double-clicking it, an installation window will pop up. Click on **Next >** to start the installation:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_06.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

Accept the **terms in the License Agreement** and then click on **Next >**:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_07.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

Go for the **Typical** installation (which is much easier) and then click on **Next >**:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_08.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

Select the two first options as in the image and then click on **Next >**:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_09.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

Click on **Install**

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_10.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

The installation has been completed. Click on **Finish** and everything should be ready.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_11.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

</details>

<details>
<summary>On Linux:</summary>

Most Unix / Linux operating system distributions include Tcl and Tk. If they are not already installed, you can use your system's package manager to install the appropriate packages. For instance, in Ubuntu, you can use the following commands:

```
sudo apt-get install tcl
```
```
sudo apt-get install tk
```

</details>

<details>
<summary>On Mac:</summary>

Most Mac OS X operating system distributions include Tcl/Tk. 

If not already installed, you will get an error similar to the following one:

```
DEPRECATION WARNING: The system version of Tk is deprecated and may be removed in a future release. Please don't rely on it. Set TK_SILENCE_DEPRECATION=1 to suppress this warning.
```
you can install or update the appropriate packages in two different ways:

 * Option 1: using homebrew:
   Reinstall you tcl-tk packages
   ```
   brew uninstall tcl-tk
   brew install tcl-tk
   ```

   **Note**: If you don't have the `brew` command, you must install [Homebrew](https://brew.sh/). You can do this by running the following command in your terminal:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

 * Option 2: using a package installation:
   
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


## 3. Download the DL4MicEverywhere repository

* **Option 1**: Download the ZIP file from GitHub's repository

    1.- Download a ZIP file with the DL4MicEverywhere repository by clicking [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip).

    2.- Decompress the downloaded file.

* **Option 2**: Download from the terminal using git

    > ❗**IMPORTANT**:
    > You need to have `git` installed. If not, follow the [official installation steps](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

    > ℹ️ **NOTE**:
    > You need to be located in the folder where you want to download the DL4MicEverywhere repository.

    ```
    git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
    ```

