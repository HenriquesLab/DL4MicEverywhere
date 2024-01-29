
import os
import sys

def add_docker_extra(filename_path):
    f = open(filename_path, "a")
    
    f.write('\n')

    f.close()

def create_docker_arguments(filename_path, base_image, path_to_notebook, path_to_requirements,
         sections_to_remove, notebook_name, gpu_flag, python_version
         ):
    
    f = open(filename_path, "w")
    
    f.write('The arguments that have been used to build the Docker image are:\n')
    f.write(f'\tBASE_IMAGE="{base_image}"\n')
    f.write(f'\tPATH_TO_NOTEBOOK="{path_to_notebook}"\n')
    f.write(f'\tPATH_TO_REQUIREMENTS="{path_to_requirements}"\n')
    f.write(f'\tSECTIONS_TO_REMOVE="{sections_to_remove}"\n')
    f.write(f'\tNOTEBOOK_NAME="{notebook_name}"\n')
    f.write(f'\tGPU_FLAG="{gpu_flag}"\n')
    f.write(f'\tPYTHON_VERSION="{python_version}"\n')
    f.close()

if __name__ == '__main__':
    if len(sys.argv) == 9:
        filename_path = sys.argv[1]

        base_image = sys.argv[2]
        path_to_notebook = sys.argv[3]
        path_to_requirements = sys.argv[4]
        sections_to_remove = sys.argv[5]
        notebook_name = sys.argv[6]
        gpu_flag = sys.argv[7]
        python_version = sys.argv[8]

        sys.exit(create_docker_arguments(filename_path, base_image, path_to_notebook, path_to_requirements, 
                      sections_to_remove, notebook_name, gpu_flag, python_version))
    else:
        sys.exit(1)