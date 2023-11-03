# Requirements
# Launch the GUI

Once the requirements have been installed, to launch the GUI, you should execute the following command on the terminal:

```
sudo -E bash launch.sh
```

After running the previous command, the following window will pop up:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

## Simple usage

The previous image shows how the simple usage looks like. There a default list of notebooks is given, first you will need to chose the folder you want to take the model from:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DEFAULT_1.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

The folders that will appear are: 
 - [Bespoke_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/Bespoke_notebooks/README.md)
 - [External_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/External_notebooks/README.md)
 - [ZeroCostDL4Mic_notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/ZeroCostDL4Mic_notebooks/README.md)

Once you have selected the folder, you will need to select the notebook that you want to use from the second list:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DEFAULT_2.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

In this case we have selected the pix2pix notebook from ZeroCost folder:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DEFAULT_RESULT.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

Once the notebook has been selected the are only two arguments that are really mandatory: **Data folder** and **Output folder**. 

### Choose the data folder

On the **Path to the data folder** section you can directly paste the path to the file or click on the **Select** button. 

The path you select here needs to be to the folder that allocates the data you want to use in your model: the images for training, the weights of a pretrained model, etc. By cliking **Select** button, a window with your file system will open:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DATA.png" 
     alt="Window to choose the data folder"
     width="60%" 
     height="60%" />

Once you have selected the path to the folder, the main window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/DATA_RESULT.png" 
     alt="Main window after data folder"
     width="40%" 
     height="40%" />


### Choose the output folder

On the **Path to the output folder** section you can directly paste the path to the file or click on the **Select** button. 


> ⚠️: **IMPORTANT:**
> Only the files you store in this folder will be saved once you close the program, the rest will be lost.

The path you select here needs to be to the folder where you are going to save and store the results of the notebook. By cliking **Select** button, a window with your file system will open:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/OUTPUT.png" 
     alt="Window to choose the output folder"
     width="60%" 
     height="60%" />

Once you have selected the path to the folder, the main window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/OUTPUT_RESULT.png" 
     alt="Main window after output folder"
     width="40%" 
     height="40%" />

With these arguments, you will be ready to click **Done** and execute the program. Additionally, you can select to use GPU (if you have GPU in the device you are runing this program) and you can give a custom tag to the Docker image that is going to be built.

### Activate/Deactivate the GPU

The **Allow GPU** checkbox will indicate if you want to use the GPU (by default is unchecked). Once selected, the main window will like:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GPU.png" 
     alt="Main window after GPU"
     width="40%" 
     height="40%" />

### Give custom tag to the Docker image

You can write the tag you want in the **Tag** textbox. In the next example we would give the tag 'MyTag' to the Docker image:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/TAG.png" 
     alt="Main window after Tag"
     width="40%" 
     height="40%" />

## Advanced usage

You can also click on the **Advanced options** button at the button and a new section will be shown:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/ADVANCED.png" 
     alt="Advanced options"
     width="40%" 
     height="40%" />

By chosing this options, the **default notebooks** section will be disabled, not taking into account the information you provide there. The rest of the arguments you provided will remain intact. In these advanced options we will be able to give paths to local files like the `configuration.yaml`, `notebook.ipynb` and `requirements.txt`.

## Select a local `configuration.yaml`:

On the **Path to the configuration.yaml** section you can directly paste the path to the file or click on the **Select** button. 

You need to select the path to the configuration.yaml file you want to use (be sure that follows the [defined structure](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/FORMAT.md)). By cliking **Select** button, a window with your file system will open:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/CONFIG.png" 
     alt="Select the local configuration"
     width="60%" 
     height="60%" />

Once selected, the window would look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/CONFIG_RESULT.png" 
     alt="Select the local configuration result"
     width="40%" 
     height="40%" />

## Select a local notebook:

Similar to the `configuration.yaml` file selection, you can select a `.ipynb` notebook instead of the one provided on the `configuration.yaml` that follows the ZeroCostDL4Mic structure:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/NOTEBOOK.png" 
     alt="Select the local notebook"
     width="60%" 
     height="60%" />

Once selected, the window would look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/NOTEBOOK_RESULT.png" 
     alt="Select the local notebook result"
     width="40%" 
     height="40%" />

### Select a local requirements file:

You can also select a `requirements.txt` file instead of the one provided on the `configuration.yaml` with the Python libraries that you want to be installed in the container:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/REQUIREMENTS.png" 
     alt="Select the local requiremnts"
     width="60%" 
     height="60%" />

Once selected, the window would look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/REQUIREMENTS_RESULT.png" 
     alt="Select the local requiremnts result"
     width="40%" 
     height="40%" />

# Connection with remote workstations through SSH

It is possible to get the GUI working even with remote workstations when a SSH connection is established. 

**iOS / Mac**
If you are using an iOS system to connect through SSH, you need [Xquartz](https://www.xquartz.org/) to be installed. With Homebrew it can be easily done using the following command in the terminal:
```
brew install --cask xquartz
```
You need to restart the system after the installation. 

**Launching the remote SSH connection**

Try one of these: 
```
ssh -Y ocb@XXX.XX.XX.XXX
```
or 
```
ssh -L -Y ocb@XXX.XX.XX.XXX
```
or
```
ssh -X ocb@XXX.XX.XX.XXX
```
or 
```
ssh -L -X ocb@XXX.XX.XX.XXX
```
**Run DL4MicEverywhere**
```
cd DL4MicEverywhere
sudo -E bash launch.sh
```
**Launch Jupyter lab with the remote port**
After the docker image is built and Jupyter lab is launched remotely, you need to connect with SSH also to the port given to Jupyter. For this, check in the new window what's the port. E.g., in the image below it is `8888`
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTER_TOKEN_TERMINAL.png" 
     alt="Terminal after running Jupyter Lab"
     width="60%" 
     height="60%" />

To establish the connection, open a new window in the Terminal and type:
```
ssh -L 8888:localhost:8888 ocb@172.22.50.188
```
Copy the path given by the terminal in a browser (the one highlighted in the screenshot above).
