from yaml import SafeDumper
import yaml
import sys
import os
import pandas as pd

from dict_parser import dict_dl4miceverywhere_to_version

def main(notebook_name):
    # Read the versions of the notebooks
    all_notebook_versions = pd.read_csv("https://raw.githubusercontent.com/HenriquesLab/ZeroCostDL4Mic/master/Colab_notebooks/Latest_Notebook_versions.csv", dtype=str)
    zerocost_version = all_notebook_versions[all_notebook_versions["Notebook"] == dict_dl4miceverywhere_to_version[notebook_name]]['Version'].iloc[0]
    
    # Go through all the notebooks and check if the version is the same
    dl4miceverywhere_notebooks_path = 'DL4MicEverywhere/notebooks/ZeroCostDL4Mic_notebooks'
    config_path = os.path.join(dl4miceverywhere_notebooks_path, notebook_name, 'configuration.yaml')
    
    # Read the information from configuration file and modify values
    with open(config_path, 'r') as f:
        config_data = yaml.safe_load(f)
        config_data['config']['dl4miceverywhere']['notebook_version'] = f'{zerocost_version}'

    # Dumper to avoid null values and instead let the atributes empty
    SafeDumper.add_representer(
        type(None),
        lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
    )

    # Writing a new yaml file with the modifications
    with open(config_path, 'w') as new_f:
        yaml.safe_dump(config_data, new_f, width=10e10, default_flow_style=False)

if __name__ == '__main__':
    if len(sys.argv) != 1:
        sys.exit(main(sys.argv[1]))
    else:
        sys.exit(1)