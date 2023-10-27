# DL4MicEverywhere User Guide

DL4MicEverywhere provides an easy way to run deep learning notebooks for microscopy analysis on your local machine or remote infrastructure. This guide covers the steps to get started.

## Installation

To use DL4MicEverywhere, you need:

- Docker installed on your system 
- For GPU usage - NVIDIA GPU + CUDA drivers

**Clone the repo:**

```
git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
```

**Navigate to the repo directory:**

```
cd DL4MicEverywhere
```

That's it for installation! Docker wraps up all the dependencies needed to run the notebooks.

## Quickstart 

**Launch the notebook selection GUI:**

```
./launch.sh
```

This will open a GUI window to choose a notebook. 

**Select a notebook:**

Choose one of the listed notebooks like U-Net 2D or StarDist 3D. This will populate the description on the right.

**Specify data and output folders:** 

Use the GUI to select the folder with your input data and the folder to save results. 

**Click "Run" to launch the notebook:**

This will build a Docker container for the selected notebook and then start it. Follow the prompts to access the Jupyter interface through your web browser.

And you're ready to run deep learning workflows through an intuitive UI!

## Advanced Configuration

For more advanced use, `launch.sh` supports additional options:

```
./launch.sh -h
```

You can specify custom locations for the configuration file, notebook, requirements, and Docker tag. Advanced mode in the GUI also allows this.

Other flags include:

- `-g` to enable GPU 
- `-i` to force GUI mode
- `-x` for debug text output 

See `./launch.sh -h` for specifics.

## Next Steps

- Try out different notebooks for your analysis needs
- Mount additional data folders to `/home/data` 
- Connect on GitHub to join the community and contribute!

Let us know if you have any issues getting started or suggestions to improve the project.
