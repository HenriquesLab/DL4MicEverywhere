# Requirements

The only requirement to use the graphical user interface (GUI) is to have [Tcl/Tk](https://www.tcl.tk/) on your computer. Choose the option of your operative system:

<details>
<summary>On Windows:</summary>

To install Tcl/Tk on you Windows computer these are the steps to follow.

First of all, got to https://www.tcl.tk/software/tcltk/ and click on the Active Tcl [link](https://www.activestate.com/products/tcl/): 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_01.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

In this case, as you are using windows click on the Windows option:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_02.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Then you will need to create an account to be able to download the installation file:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_03.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Once you create an account, you will need to download the Windows executable:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_04.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

Find where has your executable been downloaded:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_05.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

and after double-clicking it an installation window will pop-up. Click on **Next >** to start the installation:

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

The installation has been completed, click on **Finish** and everything should be ready.

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_11.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

</details>

<details>
<summary>On Linux:</summary>

Most Unix / Linux operating system distributions, include Tcl/Tk. If not already installed, you can use your system's package manager to install the appropriate packages.

```
sudo apt-get install tcl
```
```
sudo apt-get install tk
```

</details>

<details>
<summary>On Mac:</summary>

Most Mac OS X operating system distributions, include Tcl/Tk. 

If not already installed or you get an error similar to the following one:

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

   **Note**: If you don't have the `brew` command available, you need to install [Homebrew](https://brew.sh/). You can do this by running the following command in your terminal:
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

 * Option 2: using a package installation:
   
   Go to https://www.tcl.tk/software/tcltk/ and click on the Active Tcl [link](https://www.activestate.com/products/tcl/): 

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_01.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   In this case, as you are using windows click on the macOS option:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_02_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Then you will need to create an account to be able to download the installation file:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_03.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Once you create an account, you this window will be shown, don't worry click on **View all Available Builds**:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_04_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   and then click on the **Download** button to get the `.pkg` file:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_05_Mac.png" 
     alt="Main window"
     width="80%" 
     height="80%" />

   Then find the package that you have downloaded:

   <img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TCL_06_Mac.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

   and after double-clicking it an installation window will pop-up. Click on **Continue** to start the installation:

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

# Launch the GUI

Once the requirements have been installed, to launch the GUI, you should execute the following command on the terminal:

```
sudo bash launch.sh
```

> :information_source: **NOTE:**
> Be sure that the terminal is located in the same folder has `launch.sh` file is.

After running the previous command, the following window will pop up:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_01.png" 
     alt="Main window"
     width="60%" 
     height="60%" />

## Mandatory arguments

There there are only two arguments that are really mandatory: **Configuration file** and **Data folder**. 

### Choose the configuration file

On the **Path to the configuration.yaml** section you can directly paste the path to the file or click on the **Select** button and it will open a window with your file system:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_02.png" 
     alt="Select configuration file"
     width="60%" 
     height="60%" />
 
there you need to select the `configuration.yaml` file you want to use (be sure that follows the [defined structure](https://github.com/HenriquesLab/DL4MicEverywhere/wiki/Configuration-structure)). Once you select the configuration file, your selection will appear in the main window:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_03.png" 
     alt="Main window with after configuration file"
     width="60%" 
     height="60%" />

### Choose the data folder

You will need to do similarly in the **Path to the folder** section. In this case you need to select the folder that will be linked to the container. That is why, in order to access the data, you will need to have your data on it. Also the results that you want to change need to be saved here. Once the folder has been selected, the main window would look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_04.png" 
     alt="Main window after data folder"
     width="60%" 
     height="60%" />

With these arguments, you will be ready to click **Done** and execute the program. 

## Optional arguments

All these arguments are optional, therefore you can click **Done** and execute the program at any moment.

### Activate/Deactivate the GPU

The **Allow GPU** checkbox will indicate if you want to use the GPU (by default is unchecked). Once selected, the main window will like:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_07.png" 
     alt="Main window after GPU"
     width="60%" 
     height="60%" />

### Select a local notebook instead of the one provided on the `configuration.yaml`:

Similar to the `configuration.yaml` file selection, you can select a `.ipynb` notebook that follows the ZeroCostDL4Mic structure:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_05.png" 
     alt="Select the local notebook"
     width="60%" 
     height="60%" />

### Select a local requirements file instead of the one provided on the `configuration.yaml`:

You can also select a `requirements.txt` file with the Python libraries that you want to be installed in the container:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_06.png" 
     alt="Select the local requirements file"
     width="60%" 
     height="60%" />

In case you have selected all the optional arguments the main window would look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_08.png" 
     alt="Main window after local requirements"
     width="60%" 
     height="60%" />