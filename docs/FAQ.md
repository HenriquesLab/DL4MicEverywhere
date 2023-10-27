# DL4MicEverywhere FAQ

## General

**What is DL4MicEverywhere?**

DL4MicEverywhere is a project that packages deep learning workflows for microscopy into standalone Docker containers. It provides intuitive access to state-of-the-art deep learning through interactive Jupyter notebooks.

**What can I do with DL4MicEverywhere?**

You can use the packaged Jupyter notebooks for various microscopy applications like segmentation, reconstruction, registration, denoising and more without needing to code. The notebooks provide a graphical interface to configure and run different deep learning models.

**What are the requirements to run DL4MicEverywhere?**

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop))
- For GPU acceleration - NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/))

**How do I get started with DL4MicEverywhere?**

1. Clone the repo: `git clone https://github.com/HenriquesLab/DL4MicEverywhere.git`
2. Navigate to the repo directory 
3. Run `./launch.sh` to launch the notebook selection GUI
4. Choose a notebook and run!

Refer to the [step-by-step guideline](https://github.com/HenriquesLab/DL4MicEverywhere/wiki/Step%E2%80%90by%E2%80%90step-guideline) for more details.

## Usage

**How do I select and launch a notebook?**

The `launch.sh` script provides a graphical interface to select a notebook. You can choose from the list of available notebooks. The GUI also allows you to specify the input data path and output folder. Once selected, the notebook will launch in a Docker container.

**Do I need to code to use the notebooks?** 

No coding is required. The notebooks provide a graphical interface to set parameters, load data, run models, and view results.

**How do I load my own data into a notebook?**

When launching a notebook, you can specify the path to your input data folder via the GUI. This data path will be mounted into the Docker container. The notebook can then access the data files for processing.

**Can I save my work from the notebooks?**

Yes, any output generated from running the notebook will be saved to the output folder path specified when launching. This output folder is mounted into the container so files are persisted after it shuts down.

**Where are the notebook Docker images hosted?**

The Docker images are built automatically from the repo contents and hosted on Docker Hub here: [henriqueslab/dl4miceverywhere](https://hub.docker.com/u/henriqueslab). 

**How do I switch between CPU and GPU processing?**

The `launch.sh` script has a `-g` flag to enable GPU processing. If `-g` is set, the notebook will run on an Nvidia GPU-enabled Docker image. Otherwise it will use a CPU image.

**Can I use my own custom notebook?**

Yes, you can specify the path to a local notebook file when launching via the `-n` flag. This will override the notebook selection GUI. Your notebook file will be mounted into the container.

## Development

**How can I contribute to DL4MicEverywhere?**

Contributions are welcome! Check out the [contributing guidelines](CONTRIBUTING.md) to get started. Some areas for contribution include:

- Reporting bugs and issues
- Suggesting new features and enhancements 
- Improving documentation
- Adding new notebooks
- Fixing bugs




