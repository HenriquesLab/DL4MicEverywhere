from yaml import SafeDumper
import yaml
import sys
import os
from dict_parser import dict_dl4miceverywhere_to_manifest

def update_config(config_path):
    # Read the information from the manifest
    with open('../ZeroCostDL4Mic/manifest.bioimage.io.yaml', 'r', encoding='utf8') as f:
        manifest_data = yaml.safe_load(f)
    notebook_name = config_path.split('/')[-2]

    # Check if the notebook name is in the described dictionaries
    if notebook_name in dict_dl4miceverywhere_to_manifest.keys():
        # Find the name of the notebook on the manifest
        for element in manifest_data['collection']:
            if element['type'] == 'application':
                if element['id'] == dict_dl4miceverywhere_to_manifest[notebook_name]:
    
                    # Read the information from configuration file and modify values
                    with open(config_path, 'r', encoding='utf8') as f:
                        config_data = yaml.safe_load(f)
                        for key, value in element.items():
                            if key != 'config':
                                config_data[key] = value
    
                    # We only want to modify one notebook
                    break
    
        # Dumper to avoid null values and instead let the atributes empty
        SafeDumper.add_representer(
            type(None),
            lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
        )
    
        # Writing a new yaml file with the modifications
        with open(config_path, 'w', encoding='utf8') as new_f:
            yaml.safe_dump(config_data, new_f, width=10e10, default_flow_style=False)

def main():
    notebook_path = 'notebooks'
    for notebook_type in os.listdir(notebook_path):
        notebook_type_path = os.path.join('notebooks', notebook_type)
        # It will only be done for ZeroCostDL4Mic_notebooks
        if os.path.isdir(notebook_type_path) and notebook_type == "ZeroCostDL4Mic_notebooks":
            for notebook_name in os.listdir(notebook_type_path):
                if os.path.isdir(os.path.join(notebook_type_path, notebook_name)):
                    config_path = os.path.join(notebook_type_path, notebook_name, 'configuration.yaml')
                    print(config_path)
                    update_config(config_path)

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        sys.exit(main())
    else:
        sys.exit(update_config(sys.argv[1]))
