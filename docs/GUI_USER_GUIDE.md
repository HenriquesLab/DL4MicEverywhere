# Requirements
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