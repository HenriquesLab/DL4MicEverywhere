The containerization of a ZeroCostDL4Mic notebook in a static environment is based on the `configuration.yaml` file. A human-readable file that describes the arguments that will be used to create de Docker container. A [collection of configuration files](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks) from the ZeroCostDL4Mic notebooks is already provided, but they can also be defined by the user. The required elements to do so are:

* notebook_url: path to download the ZeroCostDL4Mic style notebook.
* requirements_url: path to download the requirements file that describes the Python libraries that will be included in the container.
* cuda_version: version of CUDA that will be included in the container.
* ubuntu_version: the version of Ubuntu that will be used as operative system in the container.
* python_version: the version of Ubuntu that will be installed in the container.
* sections_to_remove: the sections that you want to remove from the ZeroCost style notebook (they need to be separated by spaces and follow the X.X. format).

As example, this is the provided `configuration.yaml` file from the CARE 2D notebook:

```
notebook_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/0d2bcef99cfd76294b9b91243d68ba6c6727c4fe/Colab_notebooks/CARE_2D_ZeroCostDL4Mic.ipynb?raw=true
requirements_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/0d2bcef99cfd76294b9b91243d68ba6c6727c4fe/requirements_files/CARE_2D_requirements_simple.txt?raw=true
cuda_version: 11.8.0
ubuntu_version: 22.04
python_version: 3.10
sections_to_remove: 1.1. 1.2. 2. 6.3. 
```