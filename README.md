[![License](https://img.shields.io/github/license/HenriquesLab/DL4MicEverywhere?color=Green)](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/LICENSE.txt)
[![Contributors](https://img.shields.io/github/contributors-anon/HenriquesLab/DL4MicEverywhere)](https://github.com/HenriquesLab/DL4MicEverywhere/graphs/contributors)
[![GitHub stars](https://img.shields.io/github/stars/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)
[![GitHub forks](https://img.shields.io/github/forks/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)

<img src="https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/logo/dl4miceverywhere-logo.png" align="right" width="200"/>

# DL4MicEverywhere

DL4MicEverywhere provides researchers an accessible gateway to state-of-the-art deep learning techniques for bioimage analysis through interactive Jupyter notebooks with intuitive graphical interfaces that require no coding expertise. 
It uses Docker [containers](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) to maximize portability and reproducibility, ensuring seamless operation across diverse computing environments.

DL4MicEverywhere expands the capabilities of [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) by enabling users to run the notebooks locally on their own machines or remotely on diverse computing infrastructure including laptops, workstations, high-performance computing (HPC) and cloud infrastructure. 
It currently incorporates many existing ZeroCostDL4Mic notebooks for tasks like segmentation, reconstruction, and image translation.

## Key Features

- 15 Jupyter notebooks with intuitive graphical interface requiring no coding (scaling to 28+ soon) 
- Docker-based [packaging](https://hub.docker.com/repository/docker/henriqueslab/dl4miceverywhere) for enhanced portability and reproducibility
- Expanding [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic)'s capabilities for local use
- Covers a wide range of microscopy analysis tasks, including segmentation, reconstruction, registration, denoising, and more
- Compatible with various computing environments, including laptops, workstations, HPC, and cloud with Docker
- Automated build testing and versioning enhance reliability

![Sample Notebook](docs/images/policy.png)

## Key benefits of DL4MicEverywhere

- **Flexibility:** Notebooks can run locally, in the cloud, or on high-performance computing infrastructure. No vendor lock-in.
- **Reproducibility:** Docker containers encapsulate the full software environment. Explicit versioning maintains stability.
- **Transparency:** Notebooks and models can be readily shared to enable replication of analyses.
- **Accessibility:** Interactive widgets and automated build pipelines lower barriers for non-experts.
- **Interoperability:** Adheres to data standards like BioImage Model Zoo for model sharing.
- **Extensibility:** Automated testing and Docker building streamlines adding new methods.

DL4MicEverywhere aims to make deep learning more accessible, transparent, and participatory. This enables broader adoption of cutting-edge techniques while enhancing reliability and customization.

## Getting Started

### Requirements

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop))
- For GPU acceleration - NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/)) 
- For the graphical user interface (GUI),  [Tcl/Tk](https://www.tcl.tk/). ([Instructions](docs/GUI_USER_GUIDE.md)).

### Quickstart

1. Clone this repo: `git clone https://github.com/HenriquesLab/DL4MicEverywhere.git`
2. Navigate to the repo directory 
3. Run `sudo bash launch.sh` to launch the notebook selection GUI
4. Choose a notebook and run!

Docker wraps up all dependencies in a tidy bundle. Simply launch and access deep learning workflows through an intuitive interface!

Refer to the [User Guide](docs/USER_GUIDE.md) and [Installation guidelines](docs/INSTALLATION.md) for details.


## Contributing

We welcome contributions! Please check out the [contributing guidelines](CONTRIBUTING.md) to get started.

## Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Installation](docs/INSTALLATION.md)
- [Data Preparation](docs/DATA.md)
- [Example Notebooks](examples)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Technical Design](docs/DESIGN.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Notebook Types](docs/NOTEBOOK_TYPES.md)
- [Notebook List](docs/NOTEBOOKS.md)
- [FAQ](docs/FAQ.md)


Let us know if anything needs clarification!

## Acknowledgements

We thank the [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic) contributors for their work on the original notebooks. We also thank the [AI4Life](https://ai4life.eurobioimaging.eu/) consortium for their support, and continous feedback.
