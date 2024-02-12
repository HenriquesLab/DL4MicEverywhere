# DL4MicEverywhere Frequently Asked Questions

## General

**What is DL4MicEverywhere?**

DL4MicEverywhere is an initiative that encapsulates deep learning workflows for microscopy into standalone Docker image. It offers easy access to cutting-edge deep learning through interactive Jupyter notebooks.

**What can I do with DL4MicEverywhere?**

DL4MicEverywhere allows you to utilize the pre-packaged Jupyter notebooks for a variety of microscopy applications such as segmentation, reconstruction, registration, denoising, and more, without the need for coding. The notebooks offer a user-friendly interface to configure and execute different deep learning models.

**What are the prerequisites to run DL4MicEverywhere?**

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop)).
- For GPU acceleration - NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/)).
- For the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/).

**How do I get started with DL4MicEverywhere?**

1. Download the ZIP file of the DL4MicEverywhere repository [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip) and extract it.
2. Double-click the launcher in the DL4MicEverywhere folder that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). A GUI will automatically pop-up.
3. Choose a notebook and run!

For more detailed instructions, refer to the [step-by-step guideline](https://github.com/HenriquesLab/DL4MicEverywhere/wiki/Step%E2%80%90by%E2%80%90step-guideline).

## Usage

**How do I select and initiate a notebook?**

The `Linux_launch.sh`, `MacOS_launch.command` or `Windows_launch.bat` (depending on your operative system) scripts offer a graphical interface to select a notebook. You can choose from a list of available notebooks. The GUI also allows you to specify the input data path and output folder. Once selected, the notebook will initiate in a Docker container.

**Do I need to code to use the notebooks?** 

No, coding is not required. The notebooks offer a user-friendly interface to set parameters, load data, execute models, and view results.

**How do I load my own data into a notebook?**

When initiating a notebook, you can specify the path to your input data folder via the GUI. This data path will be mounted into the Docker container, allowing the notebook to access the data files for processing.

**Can I save my work from the notebooks?**

Yes, any output generated from running the notebook will be saved to the output folder path specified during launch. This output folder is mounted into the container, ensuring files are preserved after it shuts down.

**Where are the notebook Docker images hosted?**

The Docker images are automatically built from the repository contents and hosted on Docker Hub at: [henriqueslab/dl4miceverywhere](https://hub.docker.com/u/henriqueslab). 

**How do I switch between CPU and GPU processing?**

The [GUI](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/GUI_USER_GUIDE.md#activatedeactivate-the-gpu) has a option to choose between the use of CPU or GPU. The [CLI](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/CLI_USER_GUIDE.md#optional-arguments), which is executed with the `Linux_launch.sh` script, includes a `-g` flag to enable GPU processing (if a configure Nvidia Graphic Card can be found on your device). If `-g` is set, the notebook will run on an Nvidia GPU-enabled Docker image. Otherwise, it will use a CPU image.

**Can I use my own custom notebook?**

The [GUI](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/GUI_USER_GUIDE.md#select-a-local-notebook) has a option to select your own custom notebook. The [CLI](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/CLI_USER_GUIDE.md#optional-arguments), which is executed with the `Linux_launch.sh` script, includes `-n` argument where you can specify the path to a local notebook file, this will override the notebook defined in the `configuration.yaml` file. Your notebook file will be the one loaded into the Docker image.

## Development

**How can I contribute to DL4MicEverywhere?**

We welcome contributions! Please refer to the [contributing guidelines](CONTRIBUTING.md) to get started. Some areas for contribution include:

- Reporting bugs and issues.
- Proposing new features and enhancements. 
- Enhancing documentation.
- Adding new notebooks.
- Resolving bugs.




