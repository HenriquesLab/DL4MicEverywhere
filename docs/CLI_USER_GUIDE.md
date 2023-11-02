In case you just want to execute using the terminal this are the arguments that you can use and the command to execute the bash file. Remember that in case you want to use the graphical user interface (not giving any argument) you would need to follow the steps on the [GUI tutorial](GUI_USER_GUIDE.md).


# **Mandatory** arguments

  `-c CONFIG_PATH` : where `CONFIG_PATH` is the path to the `configuration.yaml` file (which follows the [defined structure](FORMAT.md)) you want to use for the container. This can be one from the provided configurations or a configuration file created by the user.

  `-d DATA_PATH` : where `DATA_PATH` is the path to the folder that will be linked to the container, so that you can access training, test and inference data. Relative paths are not supported. Please provide the entire path.

  `-o RESULTS_PATH` : where `RESULTS_PATH` is the path to the folder that will be linked to save any output and result from the notebook. Relative paths are not supported. Please provide the entire path.

# **Optional** arguments

  `-g`: a flag that if it is indicated it would allow the container to use the GPUs from the computer where is launched. In case you do not indicate `-g`, GPUs will not be allowed on your container.

  `-n NOTEBOOK_PATH`: where `NOTEBOOK_PATH` is the path to the local ZeroCostDL4Mic style notebook that you want to use, instead of the one referred in the `configuration.yaml`file. 

  `-r REQUIREMENTS_PATH`: where `REQUIREMENTS_PATH` is the path to the local `requirements.txt` file that you want to use, instead of the one referred in the `configuration.yaml` file. 

  `-t TAG`: where `TAG` is the tag that will be assigned to the created Docker image. In case it is not provided, the default tag would be the name of the notebook.

  `-x`: a flag to indicate if it is a test run. This has a developer use for GitHub actions and allow to see if the process has been properly done.

# **Example** usage

This would be a simple usage case, where one of the provided `configuration.yaml` files is used:

```
sudo bash launch.sh -c ./notebooks/CARE_2D_DL4Mic/configuration.yaml -d ./data_folder -o ./results_folder
```

A more complex example would be:

```
sudo bash launch.sh -c ./my_notebooks/CARE_2D_DL4Mic/configuration.yaml -d /home/user/Documents/data_folder -o /home/user/Documents/results_folder -g -n /home/user/Desktop/MyFancyZeroCostDL4MicNotebook.ipynb -r ./modified_requirements.txt -t MyNewContainer
```

where you use your own `configuration.yaml` file, your ZeroCost4Mic style notebook and your `requirements.txt`file; also allowing the container to use GPUs and giving the tag `MyNewContainer`to the docker image that will be created.