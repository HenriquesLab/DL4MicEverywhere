import os

def main():

    # Create a cache text file to store the environment name
    with open('cache.txt', 'w') as f:
        f.write('')

    notebook_path = '.conda_envs'
    for notebook_type in os.listdir(notebook_path):
        notebook_type_path = os.path.join(notebook_path, notebook_type)
        if os.path.isdir(notebook_type_path):
            for notebook_name in sorted(os.listdir(notebook_type_path)):
                notebook_name_path = os.path.join(notebook_type_path, notebook_name)
                if os.path.isdir(notebook_name_path):
                    for conda_env_name in sorted(os.listdir(notebook_name_path)):
                        if 'latest' in conda_env_name:
                            conda_env_path = os.path.join(notebook_name_path, conda_env_name)

                            # Execute the conda creation of the environment
                            result = os.system(f'conda env create -y -f {conda_env_path} -n aux_{notebook_name}')
                            
                            if result == 0:
                                # Add the environment name to the cache text file
                                with open('cache.txt', 'a') as f:
                                    f.write(f'\u2714 Success on {notebook_name}\n')
                            else:
                                # Add the environment name to the cache text file
                                with open('cache.txt', 'a') as f:
                                    f.write(f'\u274c Error on {notebook_name}\n')

                            os.system(f'conda remove -y -n aux_{notebook_name} --all') # Remove the environment

main()