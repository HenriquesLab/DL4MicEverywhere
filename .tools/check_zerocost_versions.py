from yaml import SafeDumper
import yaml
import sys
import os
import pandas as pd

from dict_parser import dict_dl4miceverywhere_to_version

def main():
    # List that will store the notebooks with the new version
    updated_notebooks = []

    # Read the versions of the notebooks
    all_notebook_versions = pd.read_csv('../ZeroCostDL4Mic/Colab_notebooks/Latest_Notebook_versions.csv', dtype=str)

    # Go through all the notebooks and check if the version is the same
    dl4miceverywhere_notebooks_path = './notebooks/ZeroCostDL4Mic_notebooks'
    for notebook in dict_dl4miceverywhere_to_version.keys():
        configuration_path = os.path.join(dl4miceverywhere_notebooks_path, notebook, 'configuration.yaml')

        # Read the information from the configuration
        with open(configuration_path, 'r') as f:
            config_data = yaml.safe_load(f)
        
        config_version = config_data['config']['dl4miceverywhere']['notebook_version']
        zerocost_version = all_notebook_versions[all_notebook_versions["Notebook"] == dict_dl4miceverywhere_to_version[notebook]]['Version'].iloc[0]
        if config_version != zerocost_version:
            updated_notebooks.append(notebook)

    for notebook in updated_notebooks: 
        print(notebook)

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        sys.exit(main())
    else:
        sys.exit(1)