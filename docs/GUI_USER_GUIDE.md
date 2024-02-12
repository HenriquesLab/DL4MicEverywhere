# Launch the GUI

After installing the necessary requirements (follow the [Requirements Installation]() in case you have not done it yet), you can launch the GUI:

### **On Linux:**
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

### **On MacOS:**
Double click the `MacOS_launch.command` file (you might get the [following message](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/TROUBLESHOOTING.md#macos_launher-cannot-be-oppened)) or run the following command in the terminal:

> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `MacOS_launch.command` is in.
```
bash MacOS_launch.command
```

### **On Windows:**
Double click the `Windows_launch.bat` file (you might get the [following message](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/TROUBLESHOOTING.md#windows_launher-cannot-be-oppened)) or run the following command in the terminal:

> ℹ️ **NOTE**:
> You need to be located in the DL4MicEverywhere folder, where `Windows_launch.bat` is in.
```
.\Windows_launch.bat
```

---

After any of these launching options, a terminal window will open. This windows will be in the background checking the requirements and executing the main code, please **DO NOT** close this window. After applying the checkings, if everything has gone well, the following GUI will appear: 

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_clean.png" 
     alt="Main window"
     width="40%" 
     height="40%" />

## Simple usage

The image above displays the simple usage interface. A default list of notebooks is provided. First, you need to choose the folder containing the model you want to use:

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

### Choose the data folder

In the **Path to the data folder** section, you can either paste the path to the file directly or click on the **Select** button. 

> ℹ️ **NOTE**:
> If you are on Windows, plese use the **Select** button instead of pasting the path. The GUI is run inside the Windows Subsystem for Linux, what changes the path's format. For example `C:\Users\username\Downloads` will need to be `/mnt/c/Users/username/Downloads`. 

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


### Choose the output folder

In the **Path to the output folder** section, you can either paste the path to the file directly or click on the **Select** button. 

> ℹ️ **NOTE**:
> If you are on Windows, plese use the **Select** button instead of pasting the path. The GUI is run inside the Windows Subsystem for Linux, what changes the path's format. For example `C:\Users\username\Downloads` will need to be `/mnt/c/Users/username/Downloads`.

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

### Activate/Deactivate the GPU

> ℹ️ **NOTE**:
> This option, will only be available if a configured Nvidia Graphic Card is detected on your computer.

The **Allow GPU** checkbox allows you to choose whether or not to use the GPU (it is unchecked by default). To use the GPU you just need to click it and a ☑️ will appear.

### Load previous setting

This option will be dissabled the first time you run DL4MicEverywhere, since there are no previous settings. Once you click `Run`, this option will be allowed for the next time. By clicking this button you will load the settings that you previously choose, facilitating the workflow in cases where you are running the same configuration multiple times. 

## Advanced usage

You can also click on the **Advanced options** button at the bottom to display a new section:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_advanced.png" 
     alt="Advanced options"
     width="40%" 
     height="40%" />

When you choose this option, the **default notebooks** section will be disabled and will not consider the information you provide there. The rest of the arguments you provided will remain intact. In these advanced options, you can provide paths to local files like the `configuration.yaml`, `notebook.ipynb`, and `requirements.txt`.

### Select a local `configuration.yaml`:

In the **Path to the configuration.yaml** section, you can either paste the path to the file directly or click on the **Select** button. 

You need to select the path to the configuration.yaml file you want to use (make sure it follows the [defined structure](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/FORMAT.md)). Clicking the **Select** button will open a window displaying your file system:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_config_select.png" 
     alt="Select the local configuration"
     width="60%" 
     height="60%" />

After selecting the file, the window should look like this:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_config.png" 
     alt="Select the local configuration result"
     width="40%" 
     height="40%" />

### Select a local notebook:

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

### Select a local requirements file:

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

### Assign a custom tag to the Docker image

You can enter the tag you want in the **Tag** textbox. In the following example, we assign the tag 'MyTag' to the Docker image:

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/GUI_USER_GUIDE/gui_tag.png" 
     alt="Main window after Tag"
     width="40%" 
     height="40%" />
     
# Connect to remote workstations via SSH

You can use the GUI with remote workstations when an SSH connection is established. 

**iOS / Mac**
If you are using an iOS system to connect via SSH, you need to install [Xquartz](https://www.xquartz.org/). You can easily do this using the following command in the terminal:
```
brew install --cask xquartz
```
You need to restart the system after the installation. 

**Launching the remote SSH connection**

Try one of these: 
```
ssh -Y username@XXX.XX.XX.XXX
```
or 
```
ssh -L -Y usernam@XXX.XX.XX.XXX
```
or
```
ssh -X username@XXX.XX.XX.XXX
```
or 
```
ssh -L -X username@XXX.XX.XX.XXX
```

The `-Y` option in the `ssh` command enables trusted X11 forwarding. This means that the remote X11 applications have permissions to connect to the local X11 display. It is a secure way to run X11 applications on a remote machine and have them displayed on a local machine. The `-Y` option is preferred over the `-X` option, for security reasons.


The `-L` option in the `ssh` command is used to set up local port forwarding. It allows you to create a secure tunnel from a local machine to a destination machine through the SSH server. This can be useful for accessing services on a remote machine securely or for bypassing firewall restrictions.
When using the `-L` option, you specify the local address and port, the remote address, and the remote port to which the traffic will be forwarded. For example, the following command sets up local port forwarding: `ssh -L 8080:localhost:80 user@remote`. This command forwards all traffic sent to port `8080` on the local machine to port `80` on the remote machine.
Local port forwarding can be used to secure traffic and access remote services securely. It is commonly used in scenarios where direct access to a service is restricted or when encryption and security are required for the communication.

**Run DL4MicEverywhere**
```
cd DL4MicEverywhere
sudo -E bash Linux_launch.sh
```
**Launch Jupyter lab with the remote port**
After the Docker image is built and Jupyter lab is launched remotely, you need to connect via SSH to the port assigned to Jupyter. To do this, check the new window for the port. For example, in the image below, it is `8888`
<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/JUPYTER_TOKEN_TERMINAL.png" 
     alt="Terminal after running Jupyter Lab"
     width="60%" 
     height="60%" />

To establish the connection, open a new window in the Terminal and type:
```
ssh -L 8888:localhost:8888 ocb@172.22.50.188
```
Copy the path given by the terminal into a browser (the one highlighted in the screenshot above).
