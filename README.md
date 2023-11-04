[![License](https://img.shields.io/github/license/HenriquesLab/DL4MicEverywhere?color=Green)](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/LICENSE.txt)
[![Contributors](https://img.shields.io/github/contributors-anon/HenriquesLab/DL4MicEverywhere)](https://github.com/HenriquesLab/DL4MicEverywhere/graphs/contributors)
[![GitHub stars](https://img.shields.io/github/stars/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)
[![GitHub forks](https://img.shields.io/github/forks/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/logo/dl4miceverywhere-logo.png" align="right" width="200"/>

# DL4MicEverywhere

DL4MicEverywhere is a platform that offers researchers an easy-to-use gateway to cutting-edge deep learning techniques for bioimage analysis. It features interactive Jupyter notebooks with user-friendly graphical interfaces that require no coding skills. 
The platform utilizes Docker [containers](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) to ensure portability and reproducibility, guaranteeing smooth operation across various computing environments.

DL4MicEverywhere extends the capabilities of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by allowing the execution of notebooks either locally on personal devices like laptops or remotely on diverse computing platforms, including workstations, high-performance computing (HPC), and cloud-based systems. 
It currently incorporates numerous pre-existing ZeroCostDL4Mic notebooks for tasks such as segmentation, reconstruction, and image translation.

## Key Features

- 15+ Jupyter notebooks with a user-friendly graphical interface that requires no coding (scaling to 28+ soon) 
- Docker-based [packaging](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) for enhanced portability and reproducibility
- Deploys the [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) user experience into local use
- Supports a wide array of microscopy analysis tasks, including segmentation, reconstruction, registration, denoising, and more
- Compatible with various computing environments, including laptops, workstations, HPC, and cloud with Docker
- Automated build testing and versioning for improved reliability

![Sample Notebook](docs/images/policy.png)

## Key benefits of DL4MicEverywhere

- **Flexibility:** Notebooks can run locally, in the cloud, or on high-performance computing infrastructure. No vendor lock-in.
- **Reproducibility:** Docker containers encapsulate the full software environment. Explicit versioning maintains stability.
- **Transparency:** Notebooks and models can be readily shared to enable replication of analyses.
- **Accessibility:** Interactive widgets and automated build pipelines lower barriers for non-experts.
- **Interoperability:** Adheres to data standards like BioImage Model Zoo for model sharing.
- **Extensibility:** Automated testing and Docker building streamline the addition of new methods.

DL4MicEverywhere is designed to make deep learning more accessible, transparent, and participatory. This enables broader adoption of advanced techniques while enhancing reliability and customization.

## Getting Started

[![alt text](https://github.com/HenriquesLab/DL4MicEverywhere/blob/documentation/Wiki%20images/ezgif.com-video-to-gif.gif)](https://youtu.be/d1FB_zc5gVc)

### Requirements

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop))
- For GPU acceleration - NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/)) 
- For the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/). ([Instructions](docs/GUI_USER_GUIDE.md)).

### Quickstart

1. Clone this repo: `git clone https://github.com/HenriquesLab/DL4MicEverywhere.git`
2. Navigate to the repo directory 
3. Run `sudo -E bash launch.sh` to launch the notebook selection GUI
4. Choose a notebook and run!

With Docker, all dependencies are neatly bundled. Just launch and access deep learning workflows through an intuitive interface!

For more details, refer to the [User Guide](docs/USER_GUIDE.md) and [Installation guidelines](docs/INSTALLATION.md).


## Contributing

We welcome contributions! Please check out the [contributing guidelines](CONTRIBUTING.md) to get started.

## Documentation

- [Installation](docs/INSTALLATION.md)
- [User Guide](docs/USER_GUIDE.md)
  - [Data Preparation](docs/DATA.md)
  - [Remote connection](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/GUI_USER_GUIDE.md#connection-with-remote-workstations-through-ssh)
- Notebooks
  - [Example Notebooks](examples)
  - [Notebook Types](docs/NOTEBOOK_TYPES.md)
  - [Notebook List](docs/NOTEBOOKS.md)
- [Docker desktop](docs/DOCKER_DESKTOP.md)
- [Technical Design](docs/DESIGN.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [FAQ](docs/FAQ.md)
- [Contributing Guidelines](CONTRIBUTING.md) 

Don't hesitate to reach out if you need any clarification!

## Acknowledgements

We extend our gratitude to the [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) contributors for their work on the original notebooks. We also thank the [AI4Life](https://ai4life.eurobioimaging.eu/) consortium for their support and continuous feedback.
