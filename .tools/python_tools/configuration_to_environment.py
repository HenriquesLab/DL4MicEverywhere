from yaml import SafeDumper
import yaml
import sys
import os
import tempfile
import urllib.request

notebook_vocals = {'ZeroCostDL4Mic_notebooks':'z',
                   'External_notebooks':'e',
                   'Bespoke_notebooks':'b'}

def create_env(config_path, environment_folder_path="", gpu_flag=0):

    if environment_folder_path=="":
        # Define am create the folder with the conda environments
        environment_folder_path = config_path.replace('/notebooks/', '/.conda_envs/').replace('/configuration.yaml', '')
    os.makedirs(environment_folder_path, exist_ok=True)

    # Read the information from configuration file
    with open(config_path, 'r') as f:
        config_data = yaml.safe_load(f)

    python_version = config_data['config']['dl4miceverywhere']['python_version']

    # Download the requirements file into a temporary folder
    requirement_url = config_data['config']['dl4miceverywhere']['requirements_url']
    temp_requirements_path = os.path.join(tempfile.gettempdir(), "requirements.txt")
    urllib.request.urlretrieve(requirement_url, temp_requirements_path)

    # Read the requirements file and extract the pip dependencies
    pip = []
    with open(temp_requirements_path, 'r') as f:
        # Read one line at a time
        requirements = f.readlines()
        for requirement in requirements:
            # If line is not empty and is not a comment, add it to the dependencies
            if requirement != '\n' and requirement[0].strip() != '#':
                if 'nbformat' not in requirement and 'ipywidgets' not in requirement and  'jupyterlab' not in requirement:
                    # Not append these libraries, as they are already added bellow
                    pip.append(requirement.replace('\n', '').strip())

    # Add pip requirements that should be in every file      
    if python_version in ['3.8', '3.9', '3.10', '3.11']:
        # For Python between 3.8 and 3.11
        pip.append('nbformat==5.9.2') 
    else:
        # For Python 3.7 or lower
        pip.append('nbformat==5.0.2') 

    if python_version in ['3.7', '3.8', '3.9', '3.10', '3.11']:
        # For Python between 3.7 and 3.11
        pip.append('ipywidgets==8.1.0') 
        pip.append('jupyterlab==3.6.0')
    elif python_version in ['3.5', '3.6']:
        # For Python 3.5 and 3.6
        pip.append('ipywidgets==8.0.0a0') 
        pip.append('jupyterlab==2.3.2')
    else:
        # For Python 3.4 or lower
        pip.append('ipywidgets==7.8.1') 
        pip.append('jupyterlab==0.23.0')

    # Create the list of dependencies
    dependecies = []
    dependecies.append(f'python={python_version}')
    dependecies.append('pip')
    dependecies.append('git')
    dependecies.append('wget')
    dependecies.append('unzip')
    dependecies.append('pkg-config')
    if gpu_flag:
        dependecies.append('cudatoolkit=11.0')
        pip.append('nvidia-cudnn-cu11==8.6.0.163')
    dependecies.append({'pip':pip})

    # Dumper to avoid null values and instead let the atributes empty
    SafeDumper.add_representer(
        type(None),
        lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
    )

    # Get the notebook name
    notebook_url = config_data['config']['dl4miceverywhere']['notebook_url']
    notebook_name = os.path.splitext(os.path.basename(notebook_url))[0].lower()

    # Get the name that will be used in the conda environment (similar to the one for Docker Hub)
    if 'docker_hub_image' in config_data['config']['dl4miceverywhere'].keys():
        environment_file_name = config_data['config']['dl4miceverywhere']['docker_hub_image']
    else:
        with open('construct.yaml', 'r') as f:
            construct_data = yaml.safe_load(f)
        dl4miceverywhere_version = construct_data['version']

        notebook_version = config_data['config']['dl4miceverywhere']['notebook_version']

        notebook_type = config_path.split('/')[-3]
        environment_file_name = f'{notebook_name}-{notebook_vocals[notebook_type]}{notebook_version}-d{dl4miceverywhere_version}'
    
    # Add the GPU flag
    if gpu_flag:
        environment_file_name += '-gpu'

    # Create the path to the conda environment file
    environment_file_path = os.path.join(environment_folder_path, environment_file_name + '.yml')

    # Create and write the environment yml file 
    env_data = {}
    with open(environment_file_path, 'w') as new_f:
        env_data['name'] = 'dl4miceverywhere'
        env_data['channels'] = ['defaults', 'anaconda', 'conda-forge']
        env_data['dependencies'] = dependecies
        yaml.safe_dump(env_data, new_f, width=10e10, default_flow_style=False)

    # Create the 'latest' environment
    environment_file_name = f'{notebook_name}-latest'

    # Add the GPU flag
    if gpu_flag:
        environment_file_name += '-gpu'

    # Create the path to the conda environment file
    environment_file_path = os.path.join(environment_folder_path, environment_file_name + '.yml')

    # Create and write the latest environment yml file
    env_data = {}
    with open(environment_file_path, 'w') as new_f:
        env_data['name'] = 'dl4miceverywhere'
        env_data['channels'] = ['defaults', 'anaconda', 'conda-forge']
        env_data['dependencies'] = dependecies
        yaml.safe_dump(env_data, new_f, width=10e10, default_flow_style=False)

def main(gpu_flag=0):
    notebook_path = './notebooks'
    for notebook_type in os.listdir(notebook_path):
        notebook_type_path = os.path.join(notebook_path, notebook_type)
        if os.path.isdir(notebook_type_path):
            for notebook_name in os.listdir(notebook_type_path):
                if os.path.isdir(os.path.join(notebook_type_path, notebook_name)):
                    config_path = os.path.join(notebook_type_path, notebook_name, 'configuration.yaml')
                    create_env(config_path, gpu_flag=gpu_flag)

if __name__ == '__main__':
    if len(sys.argv) <= 2:
        sys.exit(main(gpu_flag=int(sys.argv[1])))
    elif len(sys.argv) == 3:
        sys.exit(create_env(sys.argv[1], gpu_flag=int(sys.argv[2])))
    else:
        sys.exit(create_env(sys.argv[1], environment_folder_path=sys.argv[2], gpu_flag=int(sys.argv[3])))
