import yaml
import sys
import os

notebook_vocals = {'ZeroCostDL4Mic_notebooks':'z',
                   'External_notebooks':'e',
                   'Bespoke_notebooks':'b'}

def read_one_block_of_yaml(filename, key):
    with open(f'{filename}', 'r') as f:
        data = yaml.safe_load(f)
    return data[f'{key}']

def read_and_modify_one_block_of_yaml(filename, key, value):
    with open(f'{filename}', 'w') as f:
        data = yaml.safe_load(f)
        data[f'{key}'] = f'{value}' 

def main():
    notebook_path = 'notebooks'
    for notebook_type in os.listdir(notebook_path):
        notebook_type_path = os.path.join('notebooks', notebook_type)
        for notebook_name in os.listdir(notebook_type_path):
            config_path = os.path.join(notebook_type_path, notebook_name, 'configuration.yaml')

            dl4miceverywhere_version = read_one_block_of_yaml('construct.yaml', 'version')
            read_and_modify_one_block_of_yaml_data(config_path, 'dl4miceverywhere_version', dl4miceverywhere_version)

            notebook_version = read_one_block_of_yaml(config_path, 'config.dl4miceverywhere.notebook_version')
            notebook_url = read_one_block_of_yaml(config_path, 'config.dl4miceverywhere.notebook_url')

            notebook_name = os.path.splitext(os.path.basename(notebook_url))[0]

            docker_hub_image = f'{notebook_name}-{notebook_vocals[notebook_type]}{notebook_version}-d{dl4miceverywhere_version}'
            read_and_modify_one_block_of_yaml_data(config_path, 'docker_hub_image', docker_hub_image)

if __name__ == '__main__':
    sys.exit(main())