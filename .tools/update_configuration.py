from yaml import SafeDumper
import yaml
import sys
import os

notebook_vocals = {'ZeroCostDL4Mic_notebooks':'z',
                   'External_notebooks':'e',
                   'Bespoke_notebooks':'b'}

def update_config(config_path):
    # Read the version of the repository from the cosntruct
    with open('construct.yaml', 'r') as f:
        construct_data = yaml.safe_load(f)
    dl4miceverywhere_version = construct_data['version']

    # Read the information from configuration file
    with open(config_path, 'r') as f:
        config_data = yaml.safe_load(f)
    notebook_version = config_data['config']['dl4miceverywhere']['notebook_version']
    notebook_url = config_data['config']['dl4miceverywhere']['notebook_url']

    notebook_name = os.path.splitext(os.path.basename(notebook_url))[0].lower()
    notebook_type = config_path.splir('/')[-3]
    docker_hub_image = f'{notebook_name}-{notebook_vocals[notebook_type]}{notebook_version}-d{dl4miceverywhere_version}'

    # Read the information from configuration file and modify values
    with open(config_path, 'r') as f:
        config_data = yaml.safe_load(f)
        config_data['config']['dl4miceverywhere']['dl4miceverywhere_version'] = f'{dl4miceverywhere_version}'
        config_data['config']['dl4miceverywhere']['docker_hub_image'] = f'{docker_hub_image}'

    # Dumper to avoid null values and instead let the atributes empty
    SafeDumper.add_representer(
        type(None),
        lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
    )

    # Writing a new yaml file with the modifications
    with open(config_path, 'w') as new_f:
        yaml.safe_dump(config_data, new_f, width=10e10, default_flow_style=False)



def main():
    notebook_path = 'notebooks'
    for notebook_type in os.listdir(notebook_path):
        notebook_type_path = os.path.join('notebooks', notebook_type)
        if os.path.isdir(notebook_type_path):
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