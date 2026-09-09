import sys


def create_docker_arguments(
    filename_path,
    ubuntu_version,
    cuda_version,
    cudnn_version,
    path_to_notebook,
    path_to_requirements,
    path_to_requirements_lock,
    requirements_lock_sha256,
    sections_to_remove,
    notebook_name,
    gpu_flag,
    python_version,
):
    with open(filename_path, "w", encoding="utf8") as f:
        f.write("The arguments that have been used to build the Docker image are:\n")
        f.write(f'\tUBUNTU_VERSION="{ubuntu_version}"\n')
        f.write(f'\tCUDA_VERSION="{cuda_version}"\n')
        f.write(f'\tCUDNN_VERSION="{cudnn_version}"\n')
        f.write(f'\tPATH_TO_NOTEBOOK="{path_to_notebook}"\n')
        f.write(f'\tPATH_TO_REQUIREMENTS_INPUT="{path_to_requirements}"\n')
        f.write(f'\tPATH_TO_REQUIREMENTS_LOCK="{path_to_requirements_lock}"\n')
        f.write(f'\tREQUIREMENTS_LOCK_SHA256="{requirements_lock_sha256}"\n')
        f.write(f'\tSECTIONS_TO_REMOVE="{sections_to_remove}"\n')
        f.write(f'\tNOTEBOOK_NAME="{notebook_name}"\n')
        f.write(f'\tGPU_FLAG="{gpu_flag}"\n')
        f.write(f'\tPYTHON_VERSION="{python_version}"\n')


if __name__ == "__main__":
    if len(sys.argv) == 13:
        sys.exit(create_docker_arguments(*sys.argv[1:]))
    sys.exit(1)
