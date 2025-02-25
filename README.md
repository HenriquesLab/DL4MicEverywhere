[![License](https://img.shields.io/github/license/HenriquesLab/DL4MicEverywhere?color=Green)](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/LICENSE.txt)
[![Contributors](https://img.shields.io/github/contributors-anon/HenriquesLab/DL4MicEverywhere)](https://github.com/HenriquesLab/DL4MicEverywhere/graphs/contributors)
[![GitHub stars](https://img.shields.io/github/stars/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)
[![GitHub forks](https://img.shields.io/github/forks/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)

![Static Badge](https://img.shields.io/badge/binary_segmentation-3-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/semantic_segmentation-1-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/instance_segmentation-6-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/object_detection-3-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/denoising_&_restoration-6-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/superresolution-3-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/artificial_labelling-4-blue?labelColor=white&color=gray)
![Static Badge](https://img.shields.io/badge/registration-1-blue?labelColor=white&color=gray)

<!--
![Static Badge](https://img.shields.io/badge/macOS-9-blue?labelColor=white&color=orangered)
![Static Badge](https://img.shields.io/badge/Linux_&_Windows-5-blue?labelColor=white&color=orangered)
![Static Badge](https://img.shields.io/badge/GPU_connection-5-blue?labelColor=white&color=yellow)
-->

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/logo/dl4miceverywhere-logo.png" align="right" width="200"/>

# DL4MicEverywhere

DL4MicEverywhere is a platform that offers researchers an easy-to-use gateway to cutting-edge deep learning techniques for bioimage analysis. It features interactive Jupyter notebooks with user-friendly graphical interfaces that require no coding skills. 
The platform utilizes Docker [containers](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) to ensure portability and reproducibility, guaranteeing smooth operation across various computing environments.

DL4MicEverywhere extends the capabilities of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by allowing the execution of notebooks either locally on personal devices like laptops or remotely on diverse computing platforms, including workstations, high-performance computing (HPC), and cloud-based systems. 
It currently incorporates numerous pre-existing ZeroCostDL4Mic notebooks for tasks such as segmentation, reconstruction, and image translation.

## Key Features

- [25+ Jupyter notebooks](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/NOTEBOOKS.md) with a user-friendly graphical interface that requires no coding (scaling to 28+ soon). Corresponding docker images can be found [here](https://hub.docker.com/r/henriqueslab/dl4miceverywhere/tags).
- Docker-based [packaging](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) for enhanced portability and reproducibility.
- Deploys the [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) user experience into local use.
- Supports a wide array of microscopy analysis tasks, including segmentation, reconstruction, registration, denoising, and more.
- Compatible with various computing environments, including laptops, workstations, HPC, and cloud with Docker.
- Automated build testing and versioning for improved reliability.
- [Watch a short description](https://www.youtube.com/watch?v=kRIAls6oT4k).

![Sample Notebook](docs/images/policy.png)

## Key benefits of DL4MicEverywhere

- **Flexibility:** Notebooks can run locally, in the cloud, or on high-performance computing infrastructure. No vendor lock-in.
- **Reproducibility:** Docker containers encapsulate the full software environment. Explicit versioning maintains stability.
- **Transparency:** Notebooks and models can be readily shared to enable replication of analyses.
- **Accessibility:** Interactive widgets and automated build pipelines lower barriers for non-experts.
- **Interoperability:** Adheres to data standards like BioImage Model Zoo for model sharing.
- **Extensibility:** Automated testing and Docker building streamline the addition of new methods.

DL4MicEverywhere is designed to make deep learning more accessible, transparent, and participatory. This enables broader adoption of advanced techniques while enhancing reliability and customization.

## What is a DL4MicEverywhere notebook?

- A notebook to assist researchers in utilizing deep-learning models for image processing.
- It is fully encapsulated within a Docker container, providing a controlled and versioned snapshot of the dependencies required for the notebook.
- The versions of the required libraries are controlled upstream and downstream of the Docker container.
- The notebook is validated using continuous integration (CI) workflows to ensure compatibility with MacOS, Windows, and Linux.
- It features a user-friendly interface similar to ZeroCostDL4Mic, allowing users to train the model, perform quality checks, and run inference on new data.
- The notebook is fully traceable and open source.

## Quickstart MacOs/Linux/Windows

1. Download the ZIP file of the DL4MicEverywhere repository [here](https://github.com/HenriquesLab/DL4MicEverywhere/archive/refs/heads/main.zip) and unzip it.
2. Double-click the launcher in the DL4MicEverywhere folder that has the same name as your system (e.g., `Windows_launch` for Windows operating systems). If this is the first time you run DL4MicEverywhere, we recommend you to follow [the provided steps](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/USER_GUIDE.md#run-dl4miceverywhere-for-the-first-time).
3. A GUI will automatically pop up. Choose a notebook and run!

With Docker, all dependencies are neatly bundled. Just launch and access deep learning workflows through an intuitive interface!

Refer to the [Step-by-step "How to" guide](docs/USER_GUIDE.md) and [Requirements Installation Guidelines](docs/REQUIREMENTS_INSTALLATION.md) for further details.

Reproduce the demo in the video with the `U-Net (2D) multilabel` notebook and [Bacillus subtilis segmentation data from DeepBacs](https://zenodo.org/records/5639253). Note that run time will vary from minutes to hours depending on the GPU availability and computing resources. 

[![alt text](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/STEP_BY_STEP.gif)](https://youtu.be/rUt1aG_AXh8?si=cz1j0rwVZbfDbCXG)

#### Requirements
DL4MicEverywhere rely on the following external software that is automatically installed when launching the tool.
- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop)).
- For the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/).

If GPU acceleration is desired, the following needs to be installed:
- NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/)).

## Contributing

We welcome contributions! Please check out the [contributing guidelines](CONTRIBUTING.md) to get started.

## Documentation
- [Step-by-step "How to" guide](docs/USER_GUIDE.md)
  - [Manual Installation of the Requirements](docs/REQUIREMENTS_INSTALLATION.md)
  - [Contianerise your own pipeline](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/USER_GUIDE.md#5-containerise-your-own-pipelines-advanced-options)
- [Remote Connection](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/REMOTE_CONNECTION.md)
- Notebooks
  - [Notebook Types](docs/NOTEBOOK_TYPES.md)
  - [Notebook Format](docs/FORMAT.md)
  - [Notebook List](docs/NOTEBOOKS.md)
  - [Notebooks Folders](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks)
- [Docker Desktop](docs/DOCKER_DESKTOP.md)
- [DL4MicEverywhere Technical Design](docs/DESIGN.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [FAQ](docs/FAQ.md)
- [ZeroCostDL4Mic and DL4MicEverywhere over time](docs/DL4MicEverywhere_overtime.md)
- [Contributing Guidelines](CONTRIBUTING.md) 

Don't hesitate to reach out if you need any clarification!

## Acknowledgements

We extend our gratitude to the [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) contributors for their work on the original notebooks. We also thank the [AI4Life](https://ai4life.eurobioimaging.eu/) consortium for their support and continuous feedback.

## How to cite this work

_Iván Hidalgo-Cenalmor, Joanna W. Pylvänäinen, Mariana G. Ferreira, Craig T. Russell, Alon Saguy, Ignacio Arganda-Carreras, Yoav Shechtman, AI4Life Horizon Europe Program Consortium, Guillaume Jacquemet, Ricardo Henriques & Estibaliz Gómez-de-Mariscal.
**DL4MicEverywhere: deep learning for microscopy made flexible, shareable and reproducible.  Nat Methods 2024**
DOI: [https://doi.org/10.1038/s41592-024-02295-6](https://rdcu.be/dIdIw)_

[![NatureMethodsPaper](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/NatureMethod_Paper_Title.png)](https://rdcu.be/dIdIw)

```
@article{hidalgo2024dl4miceverywhere,
  title={DL4MicEverywhere: deep learning for microscopy made flexible, shareable and reproducible},
  author={Hidalgo-Cenalmor, Iv{\'a}n and Pylv{\"a}n{\"a}inen, Joanna W and G. Ferreira, Mariana and Russell, Craig T and Saguy, Alon and Arganda-Carreras, Ignacio and Shechtman, Yoav and Jacquemet, Guillaume and Henriques, Ricardo and others},
  journal={Nature Methods},
  pages={1--3},
  year={2024},
  publisher={Nature Publishing Group US New York}
}
```
