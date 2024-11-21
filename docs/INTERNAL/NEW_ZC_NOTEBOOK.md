# What to do when creating a new ZeroCostDL4Mic notebook?

There are few steps that you need to follow when creating a new ZeroCostDL4Mic notebook. These steps will be divided in two repositories, first the ZeroCostDL4Mic steps and after that the DL4MicEverywhere steps.

## On ZeroCostDL4Mic

There are three steps that you will need to do on ZeroCosDL4Mic. The file names on each step are allowed to be different, but the similar they are, the better that is for following everything.

1. First of all, you need to create the notebook on the [`Colab_notebooks`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/Colab_notebooks) folder directly or on the [`Beta_notebooks`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/Colab_notebooks/Beta%20notebooks) folder. In order to create the notebook, you can follow the [ZeroCostDL4Mic template](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Template_ZeroCostDL4Mic.ipynb). You can give it a name similar to `NOTEBOOK_NAME_ZeroCosDL4Mic.ipynb`.
2. Then, you will need to add the notebook version to [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file. You will need to add a line such as `NOTEBOOK_NAME,X.X.X` where `X.X.X` is the version of the notebook.
3. You need to create a requirements file on the [`requirements_files`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/requirements_files) folder. Similar to the other notebooks, it can follow the `NOTEBOOK_NAME_requirements_simple.txt` format.
4. You need to add the notebook to the [manifest](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml) file, related to the [BioImage.IO](https://bioimage.io/#/). You will need to add your notebook in the [notebook section](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml#L411), following the [format defined by BioImage.IO](https://bioimage-io.github.io/spec-bioimage-io/bioimageio_schema_latest/index.html#oneOf_i0_oneOf_i1). You can look the other notebooks on the manifest as examples, you don't need to include the `config:dl4miceverywhere` section, as it will be automatically generated later.

## On DL4MicEverywhere

After the notebook file, the version and the requirements file have been added to ZeroCostDL4Mic, it is time to add it to DL4MicEverywhere. The names you gave on previous steps will be important and referenced on this steps.

1. First of all, you will need to create the notebook folder on the [`ZeroCostDL4Mic_notebooks`](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) folder. The name of the folder can follow the `NOTEBOOK_NAME_DL4Mic` format.
2. On that folder, you will just need to create a `configuration.yaml` file that follows [our defined format](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/FORMAT.md). 
    * On the `notebook_url` argument you should point to the previously created ZeroCostDL4Mic notebook. For example: 
        ```
        notebook_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/NOTEBOOK_NAME_ZeroCostDL4Mic.ipynb
        ```
    * Similarly, on the `requirements_url` argument, you need to point to the created requirements file on ZeroCostDL4Mic. For example:
        ```
        requirements_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/requirements_files/NOTEBOOK_NAME_requirements_simple.txt
        ```
    * If everything is fell configured you don't need to add the `notebook_version`argument, it will be automatically taken from [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file. But if you want, you can also add it yourself.
3. Due to the different possible names, we needed to create a [name parser](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/python_tools/dict_parser.py). When adding a new notebook, you will need to add it's different names to this parser:
    * On `dict_manifest_to_version`, you will need to add the name of your notebook on the [manifest](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml) file (`Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`) as a key, and the name you choose on the [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file (`NOTEBOOK_NAME`) as an item. For example:
        ```
        `Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`: `NOTEBOOK_NAME`,
        ```
    * On `dict_dl4miceverywhere_to_manifest` you will need to add the name of the folder you created on DL4MicEverywhere on Step 1 (`NOTEBOOK_NAME_DL4Mic`) as a key, and the name of your notebook on the [manifest](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml) file (`Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`) as an item. For example:
        ```
        `NOTEBOOK_NAME_DL4Mic`: `Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`,
        ```
4. You can add your notebook and the results of testing it on the following file [test_files.py](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/python_tools/test_files.py) file. This will then automatically updated to generate the following[markdown](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/test-notebooks.md) file.