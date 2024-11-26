# Index 
- [check_zerocost_version.py](#check_zerocost_version.py)
- [create_docker_info.py](#create_docker_info.py)
- [dict_parser.py](#dict_parser.py)
- [list_of_notebooks.py](#list_of_notebooks.py)
- [test_files.py](#test_files.py)
- [update_configuration.py](#update_configuration.py)
- [update_with_zc_nanifest.py](#update_with_zc_nanifest.py)
- [update_zerocost_verison.py](#update_zerocost_verison.py)

---
---
## [check_zerocost_version.py](../../../../.tools/python_tools/check_zerocost_version.py) <a name="check_zerocost_version.py"></a>

### main()
Downloads [Latest_Notebook_versions.csv](https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/Latest_Notebook_versions.csv) from ZeroCostDL4Mic and compares the versions with the ones on the local repository. Returns the names of the notebooks which version's does not match the ones on ZeroCostDL4Mic.

## [create_docker_info.py](../../../../.tools/python_tools/create_docker_info.py) <a name="create_docker_info.py"></a>

Creates a file and adds the following information:

    The arguments that have been used to build the Docker image are:
        UBUNTU_VERSION="{ubuntu_version}"
        CUDA_VERSION="{cuda_version}"
        CUDNN_VERSION="{cudnn_version}"
        PATH_TO_NOTEBOOK="{path_to_notebook}"
        PATH_TO_REQUIREMENTS="{path_to_requirements}"
        SECTIONS_TO_REMOVE="{sections_to_remove}"
        NOTEBOOK_NAME="{notebook_name}"
        GPU_FLAG="{gpu_flag}"
        PYTHON_VERSION="{python_version}"

## [dict_parser.py](../../../../.tools/python_tools/dict_parser.py) <a name="dict_parser.py"></a>

On this file three dictionaries are defined:

| Variables | Keys | Values |
|---|---|---|
| dict_manifest_to_version | Names of the notebooks on [manifest.bioimage.io.yaml](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml#L411) | Names of the notebooks on [Latest_Notebook_versions.csv](https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/Latest_Notebook_versions.csv)  |
| dict_dl4miceverywhere_to_manifest | Names of the notebooks on [DL4MicEverywhere](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) | Names of the notebooks on [manifest.bioimage.io.yaml](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml#L411) |
| dict_dl4miceverywhere_to_version | Names of the notebooks on [DL4MicEverywhere](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) | [Latest_Notebook_versions.csv](https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/Latest_Notebook_versions.csv) |



## [list_of_notebooks.py](../../../../.tools/python_tools/list_of_notebooks.py) <a name="list_of_notebooks.py"></a>



## [test_files.py](../../../../.tools/python_tools/test_files.py) <a name="test_files.py"></a>

## [update_configuration.py](../../../../.tools/python_tools/update_configuration.py) <a name="update_configuration.py"></a>

## [update_with_zc_nanifest.py](../../../../.tools/python_tools/update_with_zc_nanifest.py) <a name="update_with_zc_nanifest.py"></a>

## [update_zerocost_verison.py](../../../../.tools/python_tools/update_zerocost_verison.py) <a name="update_zerocost_verison.py"></a>