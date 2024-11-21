# What to Do When Creating a New ZeroCostDL4Mic Notebook?

There are a few steps you need to follow when creating a new ZeroCostDL4Mic notebook. These steps are divided between two repositories: **ZeroCostDL4Mic** and **DL4MicEverywhere**.  

## On ZeroCostDL4Mic  

There are four steps to complete on ZeroCostDL4Mic. While file names in each step can vary, keeping them as similar as possible is recommended to maintain consistency.  

1. **Create the Notebook**:  
   - Create the notebook in either the [`Colab_notebooks`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/Colab_notebooks) folder or the [`Beta_notebooks`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/Colab_notebooks/Beta%20notebooks) folder.  
   - Use the [ZeroCostDL4Mic template](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Template_ZeroCostDL4Mic.ipynb) as a starting point.  
   - Name the notebook using a format similar to `NOTEBOOK_NAME_ZeroCostDL4Mic.ipynb`.  

2. **Update the Notebook Version**:  
   - Add the notebook version to the [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file.  
   - Add a line like `NOTEBOOK_NAME,X.X.X`, where `X.X.X` is the version of the notebook.  

3. **Create a Requirements File**:  
   - Create a requirements file in the [`requirements_files`](https://github.com/HenriquesLab/ZeroCostDL4Mic/tree/master/requirements_files) folder.  
   - Follow the format `NOTEBOOK_NAME_requirements_simple.txt`, as used in other notebooks.  

4. **Add the Notebook to the Manifest**:  
   - Add the notebook to the [manifest](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml) file for the [BioImage.IO](https://bioimage.io/#/).  
   - Update the [notebooks section](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml#L411) with the notebook details, following the [BioImage.IO format](https://bioimage-io.github.io/spec-bioimage-io/bioimageio_schema_latest/index.html#oneOf_i0_oneOf_i1).  
   - You can use existing notebooks in the manifest as examples.  
   - Note: You don’t need to include the `config:dl4miceverywhere` section, as it will be automatically generated later.  

---

## On DL4MicEverywhere  

After the notebook file, version, and requirements file have been added to ZeroCostDL4Mic, proceed with the following steps on DL4MicEverywhere. The names you used in the previous steps will be important and referenced here.  

1. **Create a Notebook Folder**:  
   - Create a new folder in the [`ZeroCostDL4Mic_notebooks`](https://github.com/HenriquesLab/DL4MicEverywhere/tree/main/notebooks/ZeroCostDL4Mic_notebooks) folder.  
   - Name the folder using a format like `NOTEBOOK_NAME_DL4Mic`.  

2. **Create a `configuration.yaml` File**:  
   - In the newly created folder, create a `configuration.yaml` file following [our defined format](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/FORMAT.md).  
   - In the `notebook_url` argument, point to the ZeroCostDL4Mic notebook you created earlier. For example:  
     ```yaml
     notebook_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/NOTEBOOK_NAME_ZeroCostDL4Mic.ipynb
     ```
   - In the `requirements_url` argument, point to the requirements file created earlier. For example:  
     ```yaml
     requirements_url: https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/requirements_files/NOTEBOOK_NAME_requirements_simple.txt
     ```
   - If everything is correctly configured, you don’t need to add the `notebook_version` argument. It will be automatically taken from the [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file. However, you can add it manually if desired.  

3. **Update the Name Parser**:  
   - Update the [name parser](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/python_tools/dict_parser.py) to account for the different names of the notebook:  
     - In `dict_manifest_to_version`, add the name of your notebook in the [manifest](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/manifest.bioimage.io.yaml) file (`Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`) as the key and the name in the [`Latest_Notebook_versions.csv`](https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/Latest_Notebook_versions.csv) file (`NOTEBOOK_NAME`) as the value. Example:  
       ```python
       'Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic': 'NOTEBOOK_NAME',
       ```
     - In `dict_dl4miceverywhere_to_manifest`, add the name of the folder you created in Step 1 (`NOTEBOOK_NAME_DL4Mic`) as the key and the name of your notebook in the manifest file (`Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic`) as the value. Example:  
       ```python
       'NOTEBOOK_NAME_DL4Mic': 'Notebook_NOTEBOOK_NAME_ZeroCostDL4Mic',
       ```

4. **Add the Notebook to Tests**:  
   - Add your notebook and test results to the [`test_files.py`](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/python_tools/test_files.py) file.  
   - This will automatically update and generate the associated [markdown file](https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/.tools/test-notebooks.md).  
