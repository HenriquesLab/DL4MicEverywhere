[![License](https://img.shields.io/github/license/HenriquesLab/DL4MicEverywhere?color=Green)](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/LICENSE.txt)
[![Contributors](https://img.shields.io/github/contributors-anon/HenriquesLab/DL4MicEverywhere)](https://github.com/HenriquesLab/DL4MicEverywhere/graphs/contributors)
[![GitHub stars](https://img.shields.io/github/stars/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)
[![GitHub forks](https://img.shields.io/github/forks/HenriquesLab/DL4MicEverywhere?style=social)](https://github.com/HenriquesLab/DL4MicEverywhere/)


# DL4MicEverywhere

DL4MicEverywhere makes state-of-the-art deep learning accessible to microscopy researchers through interactive Jupyter notebooks packaged in standalone Docker containers.

![Sample Notebook](images/sample_notebook.png)

## Key Features

- 28+ Jupyter notebooks with intuitive graphical interface requiring no coding  
- Docker-based packaging for enhanced portability and reproducibility
- Expanding [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic)'s capabilities for local use
- Segmentation, reconstruction, registration, denoising and other workflows 
- Runs on laptops, workstations, HPC and cloud with Docker
- Automatic build testing and versioning enhance reliability

## Getting Started

### Requirements

- Docker Desktop installed ([download](https://www.docker.com/products/docker-desktop))
- For GPU acceleration - NVIDIA GPU + CUDA drivers ([setup](https://docs.nvidia.com/cuda/)) 

### Quickstart

1. Clone this repo: `git clone https://github.com/HenriquesLab/DL4MicEverywhere.git`
2. Navigate to the repo directory 
3. Run `./launch.sh` to launch the notebook selection GUI
4. Choose a notebook and run!

Docker wraps up all dependencies in a tidy bundle. Simply launch and access deep learning workflows through an intuitive interface!

Refer to the [step-by-step guideline](https://github.com/HenriquesLab/DL4MicEverywhere/wiki/Step%E2%80%90by%E2%80%90step-guideline) for details.

## Contributing

We welcome contributions! Please check out the [contributing guidelines](CONTRIBUTING.md) to get started.

## Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Example Notebooks](examples)
- [Technical Design](docs/DESIGN.md)

Let us know if anything needs clarification!
