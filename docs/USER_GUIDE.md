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
DL4MicEverywhere comes packaged with an executable for each operating system. Double-click on the one that has the same name as your system (e.g., `Windows_launch` for Windows operating systems).

To run DL4MicEverywhere for the first time you need to have root/admin permissions as the program will check for the presence of the requirements and will attempt to install any that are missing. 

If it encounters an issue during the automatic installation of the requirements, the [REQUIREMENTS INSTALLATION](REQUIREMENTS_INSTALLATION.md) page has detailed information about the requirements and intructions on how to manually install them.
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


## Step-by-step guide to use DL4MicEverywhere notebooks


### 1. Launch DL4MicEverywhere

Double-click the launcher in the DL4MicEverywhere folder that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). A GUI will automatically pop-up.

<details>
<summary>On Linux:</summary>


Run the following command in the terminal:
> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `Linux_launch.sh` is in.
```
bash Linux_launch.sh
```

If you want a double click file, you will need to run the following command in the terminal:
> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `.tools` folder is in.
```
bash .tools/create_desktop.sh
```
This will create a `DL4MicEverywhere.desktop` file in your Desktop. You will need to right click the file and ´Allow Launching´, after that you will always be able to launch DL4MicEverywhere by double clicking it.  

</details>

<details>
<summary>On MacOs:</summary>


Double click the `MacOS_launch.command` file (you might get the [following message](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/TROUBLESHOOTING.md#macos_launher-cannot-be-oppened)) or run the following command in the terminal:

> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `MacOS_launch.command` is in.
```
bash MacOS_launch.command
```
</details>

<details>
<summary>On Windows:</summary>


Double click the `Windows_launch.bat` file (you might get the [following message](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/TROUBLESHOOTING.md#windows_launher-cannot-be-oppened)) or run the following command in the terminal:

> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `Windows_launch.bat` is in.
```
.\Windows_launch.bat
```
</details>

---

After using the appropriate launching option, a terminal window will open. This window will be in the background checking the requirements and executing the main code, please **DO NOT** close this window. Afterwards, if everything has gone well, the following GUI will appear: 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_clean.png" 
     alt="Main window"
     width="40%" 
     height="40%" />
     
DL4MicEverywhere can also be launched, without GUI, via the command line, check out our [CLI User Guide](docs/CLI_USER_GUIDE.md) for how to do it.

### 2. GUI interface

The image below displays the basic GUI interface. A default list of model notebooks is provided. First, you need to choose the folder containing the model you want to use:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_notebook_type.png" 
     alt="Notebook type"
     width="30%" 
     height="30%" />

The available folders are: 
 - [Bespoke_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/Bespoke_notebooks/README.md)
 - [External_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/External_notebooks/README.md)
 - [ZeroCostDL4Mic_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/ZeroCostDL4Mic_notebooks/README.md)

After selecting the folder, you need to choose the notebook you want to use from the second list:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_notebook_name.png" 
     alt="Main window"
     width="30%" 
     height="30%" />

After selecting the notebook, there are only two mandatory arguments: **Data folder** and **Output folder**. 

#### Choose the data folder

In the **Path to the data folder** section, you can either paste the path to the file directly or click on the **Select** button. 

> ℹ️ **NOTE**:
> If you are on Windows, plese use the **Select** button instead of pasting the path. The GUI is run inside the Windows Subsystem for Linux, that changes the path's format. For example `C:\Users\username\Downloads` will need to be `/mnt/c/Users/username/Downloads`. 

The path you select here should lead to the folder containing the data you want to use in your model, such as the images for training, the weights of a pretrained model, etc. Clicking the **Select** button will open a window displaying your file system:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DATA.png" 
     alt="Window to choose the data folder"
     width="60%" 
     height="60%" />

After selecting the path to the folder, the main window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_data.png" 
     alt="Main window after data folder"
     width="40%" 
     height="40%" />


#### Choose the output folder

In the **Path to the output folder** section, you can either paste the path to the file directly or click on the **Select** button. 

> ℹ️ **NOTE**:
> If you are on Windows, plese use the **Select** button instead of pasting the path. The GUI is run inside the Windows Subsystem for Linux, that changes the path's format. For example `C:\Users\username\Downloads` will need to be `/mnt/c/Users/username/Downloads`.

> ⚠️: **IMPORTANT:**
> Only the files you store in this folder will be saved once you close the program, the rest will be lost.

The path you select here should lead to the folder where you plan to save and store the results of the notebook. Clicking the **Select** button will open a window displaying your file system:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/OUTPUT.png" 
     alt="Window to choose the output folder"
     width="60%" 
     height="60%" />

After selecting the path to the folder, the main window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_output.png" 
     alt="Main window after output folder"
     width="40%" 
     height="40%" />

With these arguments set, you can click **Run** to execute the program. Additionally, you can choose to use a GPU (if your device has one) and you can assign a custom tag to the Docker image that will be built.

#### Activate/Deactivate the GPU

> ℹ️ **NOTE**:
> This option, will only be available if a configured Nvidia Graphic Card is detected on your computer.

The **Allow GPU** checkbox allows you to choose whether or not to use the GPU (it is unchecked by default). To use the GPU you just need to click it and a ☑️ will appear.

#### Load previous setting

The first time you run DL4MicEverywhere this setting will be disabled, as there are no previous settings. Once you click `Run`, the used settings will be stored and will be available in the next time you run DL4MicEverywhere. By clicking this button you will load the last settings that were used, facilitating the workflow in cases where you are running the same configuration multiple times. 

#### Advanced options

Clicking on the **Advanced options** button at the bottom will display a new section:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_advanced.png" 
     alt="Advanced options"
     width="40%" 
     height="40%" />

When you choose this option, the **default notebooks** section will be disabled and will not consider the information you provide there. The rest of the arguments you provided will remain intact. In the advanced options, you can provide paths to local files of the `configuration.yaml`, `notebook.ipynb`, and `requirements.txt`.

#### Select a local `configuration.yaml`:

In the **Path to the configuration.yaml** section, you can either paste the path to the file directly or click on the **Select** button. 

Providing a valid `configuration.yaml` file is **mandatory** when using the advanced options. You need to select the path to the configuration.yaml file you want to use (make sure it follows the [defined structure](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/FORMAT.md)). Clicking the **Select** button will open a window displaying your file system:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_config_select.png" 
     alt="Select the local configuration"
     width="60%" 
     height="60%" />

After selecting the file, the window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_config.png" 
     alt="Select the local configuration result"
     width="40%" 
     height="40%" />

#### Select a local notebook:

Just like the `configuration.yaml` file selection, you can select a `.ipynb` notebook instead of the one provided in the `configuration.yaml` that follows the ZeroCostDL4Mic structure:


<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_notebook_select.png" 
     alt="Select the local notebook"
     width="60%" 
     height="60%" />

After selecting the file, the window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_notebook.png" 
     alt="Select the local notebook result"
     width="40%" 
     height="40%" />

#### Select a local requirements file:

You can also select a `requirements.txt` file instead of the one provided in the `configuration.yaml`. This file should contain the Python libraries that you want to be installed in the container:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_requ_select.png" 
     alt="Select the local requirements"
     width="60%" 
     height="60%" />

After selecting the file, the window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_requ.png" 
     alt="Select the local requirements result"
     width="40%" 
     height="40%" />

#### Assign a custom tag to the Docker image

You can enter the tag you want in the **Tag** textbox. In the following example, we assign the tag 'MyTag' to the Docker image:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_tag.png" 
     alt="Main window after Tag"
     width="40%" 
     height="40%" />
 

### 3. Docker images

DL4MicEverywhere will either pull a container image from Dockerhub or build one for you if there isn't one suitable for your operating system and configuration. The interface may ask you:

1. if there is already an image on your machine, would you like to rebuild and replace it?
2. if there is no image on your machine but there is one on Docker hub, would you like to download it?

> ℹ️ **NOTE**:
> Your system might require root access or password authentication to build a Docker image.
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/PASSWORD_BUILDIMAGE.png" 
     alt="Root access is required to build a docker image"
     width="40%" 
     height="40%" />
   
While building or pulling the image, your terminal window will look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/IMAGE_BUILD_TERMINAL.png" 
     alt="Terminal after building a docker image"
     width="60%" 
     height="60%" />

Docker images occupy between 3 and 5 GB of memory, so it is advisable to manage them periodically. Check how to do it [here](DOCKER_DESKTOP.md)

### 4. Working with DL4MicEverywhere notebooks
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
