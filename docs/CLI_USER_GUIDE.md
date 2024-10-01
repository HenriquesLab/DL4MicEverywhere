# DL4MicEverywhere Command Line Interface (CLI) User Guide

If you prefer to execute using the terminal, the following are the arguments you can use along with the command to execute the bash file. 
Note that if you wish to use the graphical user interface (without providing any argument), you need to follow the steps in the main [User Guide](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/USER_GUIDE.md#1-launch-dl4miceverywhere) to launch DL4MicEverywhere.

# **Mandatory** arguments

  `-c CONFIG_PATH` : `CONFIG_PATH` is the path to the `configuration.yaml` file (which adheres to the [defined structure](FORMAT.md)) you want to use for the container. This can be one of the provided configurations or a configuration file created by the user.

  `-d DATA_PATH` : `DATA_PATH` is the path to the folder that will be linked to the container, allowing you to access training, test, and inference data. Relative paths are not supported. Please provide the full path.

  `-o RESULTS_PATH` : `RESULTS_PATH` is the path to the folder that will be linked to save any output and result from the notebook. Relative paths are not supported. Please provide the full path.

# **Optional** arguments

  `-g`: This flag allows the container to use the GPUs from the computer where it is launched. If `-g` is not specified, GPUs will not be available in your container.

  `-n NOTEBOOK_PATH`: `NOTEBOOK_PATH` is the path to the local ZeroCostDL4Mic style notebook that you want to use, instead of the one referred to in the `configuration.yaml` file. 

  `-r REQUIREMENTS_PATH`: `REQUIREMENTS_PATH` is the path to the local `requirements.txt` file that you want to use, instead of the one referred to in the `configuration.yaml` file. 

  `-t TAG`: `TAG` is the tag that will be assigned to the created Docker image. If it is not provided, the default tag from the configuration file will be taken and if that configuration file does not have a tag a custom one will be generated with name and version of the notebook.

  `-p PORT_NUMBER`: `PORT_NUMBER` is the port number that the notebook will be open on: `http://127.0.0.1:PORT_NUMBER`. If it is not provided, the default port number `8888` will be used. Still, in both cases, if the port is not accessible and consecutive accessible one will be found. 

  `-x`: This flag indicates a test run. It is primarily used for GitHub actions and allows developers to verify if the process has been executed correctly.

# **Example** usage

> ℹ️ **NOTE**:
    > You need to be located in the DL4MicEverywhere folder, where the file launch.sh is in.

### Simple usage

In this simple usage case, a `configuration.yaml` file from DL4MicEverwhere is used:

**On MacOS/Linux:**
```
bash Linux_launch.sh -c ./notebooks/CARE_2D_DL4Mic/configuration.yaml -d ./data_folder -o ./results_folder
```

**On Windows:**
```
wsl bash Linux_launch.sh -c ./notebooks/CARE_2D_DL4Mic/configuration.yaml -d ./data_folder -o ./results_folder
```

### More complex usage

In this complex usage case, you can use your own `configuration.yaml` file, your ZeroCost4Mic style notebook, and your `requirements.txt` file. You can also allow the container to use GPUs and assign the tag `MyNewContainer` to the Docker image that will be created.

**On MacOS/Linux:**
```
bash Linux_launch.sh -c ./my_notebooks/CARE_2D_DL4Mic/configuration.yaml -d /home/user/Documents/data_folder -o /home/user/Documents/results_folder -g -n /home/user/Desktop/MyFancyZeroCostDL4MicNotebook.ipynb -r ./modified_requirements.txt -t MyNewContainer
```
**On Windows:**
```
wsl bash Linux_launch.sh -c ./my_notebooks/CARE_2D_DL4Mic/configuration.yaml -d /home/user/Documents/data_folder -o /home/user/Documents/results_folder -g -n /home/user/Desktop/MyFancyZeroCostDL4MicNotebook.ipynb -r ./modified_requirements.txt -t MyNewContainer
```

