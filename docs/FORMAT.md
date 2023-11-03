The containerization of a ZeroCostDL4Mic notebook in a static environment is based on the `configuration.yaml` file. A human-readable file that describes the arguments that will be used to create de Docker container. A [collection of configuration files](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks) from the ZeroCostDL4Mic notebooks is already provided, but they can also be defined by the user. The required elements to do so are:

* `notebook_url`: path to download the Jupyter notebook.
* `requirements_url`: path to download the requirements file that describes the Python libraries that will be included in the container.
* `cuda_version`: version of CUDA that will be included in the container.
* `ubuntu_version`: the version of Ubuntu that will be used as operative system in the container.
* `python_version`: the version of Ubuntu that will be installed in the container.
* `sections_to_remove`: the sections that you want to remove from the ZeroCost style notebook (they need to be separated by spaces and follow the X.X. format).
* `version`: the version of the configuration.yaml.
* `description`: description of the notebook that is pointed in the `notebook_url`.

As example, this is the provided `configuration.yaml` file from the CARE 2D notebook:

```
notebook_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/pix2pix_ZeroCostDL4Mic.ipynb
requirements_url: https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/requirements_files/pix2pix_requirements_simple.txt
cuda_version: 11.8.0
ubuntu_version: 22.04
python_version: 3.8
sections_to_remove: 2. 6.3. 
version: 0.0.1
description: "pix2pix_DL4Mic is the conversion of the pix2pix from ZeroCostDL4Mic."
```
