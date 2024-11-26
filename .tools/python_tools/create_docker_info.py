
import sys

def create_docker_arguments(filename_path, ubuntu_version, cuda_version, cudnn_version, 
                            path_to_notebook, path_to_requirements,
                            sections_to_remove, notebook_name, gpu_flag, python_version
                            ):
    
    f = open(filename_path, "w", encoding='utf8')
    f.write('The arguments that have been used to build the Docker image are:\n')
    f.write(f'\tUBUNTU_VERSION="{ubuntu_version}"\n')
    f.write(f'\tCUDA_VERSION="{cuda_version}"\n')
    f.write(f'\tCUDNN_VERSION="{cudnn_version}"\n')
    f.write(f'\tPATH_TO_NOTEBOOK="{path_to_notebook}"\n')
    f.write(f'\tPATH_TO_REQUIREMENTS="{path_to_requirements}"\n')
    f.write(f'\tSECTIONS_TO_REMOVE="{sections_to_remove}"\n')
    f.write(f'\tNOTEBOOK_NAME="{notebook_name}"\n')
    f.write(f'\tGPU_FLAG="{gpu_flag}"\n')
    f.write(f'\tPYTHON_VERSION="{python_version}"\n')
    f.close()

if __name__ == '__main__':
    if len(sys.argv) == 11:
        filename_path = sys.argv[1]

        ubuntu_version = sys.argv[2]
        cuda_version = sys.argv[3]
        cudnn_version = sys.argv[4]
        path_to_notebook = sys.argv[5]
        path_to_requirements = sys.argv[6]
        sections_to_remove = sys.argv[7]
        notebook_name = sys.argv[8]
        gpu_flag = sys.argv[9]
        python_version = sys.argv[10]

        sys.exit(create_docker_arguments(filename_path, ubuntu_version, cuda_version, 
                                         cudnn_version, path_to_notebook, path_to_requirements, 
                                         sections_to_remove, notebook_name, gpu_flag, python_version))
    else:
        sys.exit(1)