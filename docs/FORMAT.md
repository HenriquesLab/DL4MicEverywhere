# Format of YAML Configuration Files for DL4MicEverywhere

The containerization of a ZeroCostDL4Mic notebook in a static environment is facilitated by `configuration.yaml` files. These files are easily readable and detail the parameters required for Docker container creation. A [collection of configuration files](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks) for the ZeroCostDL4Mic notebooks is readily available. However, users have the flexibility to create their own. The essential components for this process are:

* `notebook_url`: URL to download the Jupyter notebook.
* `requirements_url`: URL to download the file specifying the Python libraries to be included in the container.
* `cuda_version`: The CUDA version to be included in the container.
* `ubuntu_version`: The Ubuntu version to be used as the operating system in the container.
* `python_version`: The Python version to be installed in the container.
* `sections_to_remove`: The sections to be removed from the ZeroCost style notebook (must be separated by spaces and follow the X.X. format).
* `version`: The version of the configuration.yaml.
* `description`: A brief description of the notebook specified in the `notebook_url`.

For instance, here is the provided `configuration.yaml` file for the CARE 2D notebook:


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
