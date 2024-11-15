#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")
            
# Run pre_launch_test.sh, stop if it fails
/bin/bash "$BASEDIR/.tools/bash_tools/pre_launch_test.sh" || exit 1

# Function with the text to describe the usage of the bash script
usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue

Welcome to DL4MicEverywhere!
Providing an easy way to apply deep learning to microscopy using interactive Jupyter notebooks.
DL4MicEverywhere enables you to build/pull and run a notebook docker image. 

Below, you'll find examples of the most basic usage case, as well as all the available options for a more advanced experience.

The most basic usage case involves providing three paths (these are always required):
 - The path to the configuration file 'configuration.yaml'.
 - The path to the folder containing the data for your notebook.
 - The path to the folder where you wish to save your notebook's results.

Code example:
    $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path -o output_path

Here is a list of all available arguments:
 -h      Display this help message and exit. (optional)
 -c      Path to the configuration file 'configuration.yaml'.   
 -d      Path to the folder containing the data for your notebook.
 -o      Path to the folder where you wish to save your notebook's results.
 -g      Flag to indicate if GPU should be used. (optional)
 -n      Path to a local notebook file 'notebook.ipynb'. (optional)
 -r      Path to a local requirements file 'requirements.txt'. (optional)
 -t      Tag to be added to the docker image during building. (optional)
 -p      Port number where to open the notebook.
 -x      Flag to indicate if it is a test run. This allows for the printing of useful debugging information. (optional)

Code example:
    $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path -o output_path [-h|t|g] [-n notebook_path] [-r requirements_path] 

EOF
  exit
}

# Function to check if a given argument exists or to rename it in case is needed
rename_parsed_argument() {
    variable_name="$1"
    config_variable_name="config_dl4miceverywhere_$1"
    eval "$variable_name=\$$config_variable_name"
}

check_parsed_argument() {
    variable_name="$1"
    config_variable_name="config_dl4miceverywhere_$1"
    
    if [ -z "${!config_variable_name}" ]; then
        if [ -z "${!variable_name}" ]; then
            # Close the terminal
            echo ""
            echo "------------------------------------"
            echo "$variable_name parameter is not specified on the configuration yaml."
            echo "Please specify the $variable_name parameter on the configuration yaml."
            echo "If the problem persists, please create an issue on GitHub:"
            echo "  https://github.com/HenriquesLab/DL4MicEverywhere/issues"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        fi
    else
        rename_parsed_argument $variable_name
    fi
}

function cache_gui {
    mkdir -p "$BASEDIR/.tools/.cache"
    echo "data_path : $1
result_path : $2
selected_folder : $3
selected_notebook : $4
config_path : $5
notebook_path : $6
requirements_path : $7
flag_gpu : $8
selected_version : $9
tag : ${10}
advanced_options : ${11}" > "$BASEDIR/.tools/.cache/.cache_gui"
}


# Import get_yaml_args_from_file
source "$BASEDIR/.tools/bash_tools/get_yaml_args.sh"

# Let's define the default values for the flags
flag_gpu=0
flag_test=0
flag_local_notebook=0
flag_local_requirements=0

# Flag to check if a version was selected
flag_version_selected=0

# Let's parse the arguments
while getopts :hc:d:o:gn:r:t:p:x flag;do
    case $flag in 
        h)
            usage ;;
        c)
            config_path="$OPTARG" ;;
        d)
            data_path="$OPTARG" ;;
        o)
            result_path="$OPTARG" ;;
        g)
            if nvidia-smi &> /dev/null; then
                flag_gpu=1
            else
                echo ""
                echo "Sorry, there is no configured Nvidia graphic card on your device, the docker image will be created without GPU."
                echo ""
            fi ;;
        n)
            notebook_path="$OPTARG" ;;
        r)
            requirements_path="$OPTARG" ;;
        t)
            docker_tag="$OPTARG" ;;
        p)
            port_number="$OPTARG" ;;
        x)
            flag_test=1 ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "Try bash ./launch.sh -h for more information."
            # Close the terminal
            exit 1 ;;
    esac
done

# If no arguments are provided, set the GUI flag
if [ $# -eq 0 ]; then
    flag_gui=1
else 
    flag_gui=0
fi

# Check if test mode is active
if [ "$flag_test" -eq 1 ]; then
    echo 'Test mode is enabled.'
fi

if [ $flag_gui -eq 0 ]; then 
    # If GUI is not requested
    if [ "$flag_test" -eq 1 ]; then
        echo "GUI is not requested, proceeding with CLI."
    fi
else
    # If the GUI flag has been specified, run the function to show the GUI and read the arguments
    gui_arguments=$(wish "$BASEDIR/.tools/tcl_tools/main_gui.tcl" "$BASEDIR" "$OSTYPE")

    if [ -z "$gui_arguments" ]; then
        # No arguments were provided, this means that the GUI has been closed, so close the terminal
        exit 1
    fi

    IFS=$'\n' read -d '' -r -a strarr <<<"$gui_arguments"

    advanced_options=${strarr[0]}

    if [ $advanced_options -eq 0 ]; then
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"
        selectedFolder="${strarr[3]}"
        selectedNotebook="${strarr[4]}"
        flag_gpu="${strarr[5]}"
        selectedVersion="${strarr[6]}"
        tag_aux="${strarr[7]}"

        cache_gui "$data_path" "$result_path" "$selectedFolder" "$selectedNotebook" "" "" "" "$flag_gpu" "$selectedVersion" "$tag_aux" "$advanced_options"

        if [ "$tag_aux" != "" ]; then
            docker_tag="$tag_aux"
        elif [ "$selectedVersion" != "-" ]; then
            flag_version_selected=1
            versioned_docker_tag=$(/bin/bash "$BASEDIR/.tools/bash_tools/get_docker_tag.sh" "$selectedNotebook" "$selectedVersion")
        fi

        config_path="$BASEDIR/notebooks/$selectedFolder/$selectedNotebook/configuration.yaml"
    else
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"

        config_path="${strarr[3]}"

        notebook_aux="${strarr[4]}"
        requirements_aux="${strarr[5]}"
        
        flag_gpu="${strarr[6]}"
        selectedVersion="${strarr[7]}"
        tag_aux="${strarr[8]}"

        cache_gui "$data_path" "$result_path" "" "" "$config_path" "$notebook_aux" "$requirements_aux" "$flag_gpu" "" "$tag_aux" "$advanced_options"

        if [ "$notebook_aux" != "-" ]; then
            notebook_path="$notebook_aux"
        fi
        if [ "$requirements_aux" != "-" ]; then
            requirements_path="$requirements_aux"
        fi
        if [ "$tag_aux" != "" ]; then
            docker_tag="$tag_aux"
        fi
    fi
fi

if [ -z "$config_path" ]; then 
    # If no configuration path has been specified, then exit with the error
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the configuration.yaml file has been specified."
    echo "If you are using the CLI, please make sure to use -c argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a default"
    echo "notebook or a local oath to a configuration."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # If a configuration path has been specified, check if it is valid
    if [[ -d "$config_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
        config_path="$config_path/configuration.yaml"
    elif [[ -f "$config_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the configuration is not valid: $config_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ -z "$data_path" ]; then 
    # Exit with an error if no data path is specified
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the data folder has been specified."
    echo "If you are using the CLI, please make sure to use -d argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a path to the data folder."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # Validate the specified data path
    if [[ -d "$data_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Data path: $data_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the data folder is not valid: $data_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ -z "$result_path" ]; then 
    # Exit with an error if no result path is specified
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the output folder has been specified."
    echo "If you are using the CLI, please make sure to use -o argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a path to the output folder."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # Validate the specified result path
    if [[ -d "$result_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Result path: $result_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the output folder is not valid: $result_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ "$flag_test" -eq 1 ]; then
    # If the test flag is set, print whether the GPU flag has been set
    if [ "$flag_gpu" -eq 1 ]; then
        echo 'GPU usage is enabled.'
    else
        echo 'GPU usage is disabled.'
    fi
fi

# Read the variables from the yaml file
eval $(get_yaml_args_from_file "$config_path")

# Check the parsed variables
check_parsed_argument notebook_url
check_parsed_argument requirements_url
check_parsed_argument cuda_version
check_parsed_argument cudnn_version
check_parsed_argument ubuntu_version
check_parsed_argument python_version
check_parsed_argument notebook_version
rename_parsed_argument description # Not required to be present and therefore the cheking is skipped
rename_parsed_argument sections_to_remove # Not required to be present and therefore the cheking is skipped
rename_parsed_argument dl4miceverywhere_version # Not required to be present and therefore the cheking is skipped
rename_parsed_argument docker_hub_image # Not required to be present and therefore the cheking is skipped

# Check if the notebook path is missing (SIMPLE USECASE) 
if [ -z "$notebook_path" ]; then
    # Then the URL from the configuration file is used as notebook path
    notebook_path="${notebook_url}"

    # For the auxiliar docker tag, check if there is a notebook version
    if [ ! -z "$versioned_docker_tag" ]; then
        # If so, the corresponding versioned docker tag will be used as the auxiliar one
        aux_docker_tag="${versioned_docker_tag}"
    else
        # Otherwise, if the version is missing, 
        # check if on advanced mode a docker hub image name has been selected
        if [ ! -z "$docker_hub_image" ]; then
            # If so, assign it as auxiliar docker tag
            aux_docker_tag="${docker_hub_image}"
        else
            # Otherwise, assing it from the notebook name 
            aux_docker_tag="$(basename "$notebook_path" .ipynb)"
        fi
    fi

    if [ "$flag_test" -eq 1 ]; then
        echo "Since no notebook was specified, the notebook URL from 'configuration.yaml' will be used."
    fi
else
    # Otherwise check if the path is valid
    # If there is no versioned tag
    if [ -z "$versioned_docker_tag" ]; then
        # For the docker's tag if not specified
        if [ -z "$docker_hub_image" ]; then
            aux_docker_tag="$(basename "$notebook_path" .ipynb)"
        else
            aux_docker_tag="${docker_hub_image}"
        fi
    else
        aux_docker_tag="${versioned_docker_tag}"
    fi

    if [ -f "$notebook_path" ]; then
    
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the notebook: $notebook_path"
        fi
        
        # If the notebook path is not valid, activate its flag for future processing
        flag_local_notebook=1
    else
        echo ""
        echo "------------------------------------"
        echo "The give path to the notebook.ipynb is not valid: $notebook_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi

if [ -z "$requirements_path" ]; then
    # If no local requirements path has been specified, then the URL from the configuration file will be used
    requirements_path="${requirements_url}"
    flag_local_requirements=0
    if [ "$flag_test" -eq 1 ]; then 
        echo "No requirements file has been specified, therefore the requirements url specified on 'configuration.yaml' will be used."
    fi
else
    # Otherwise check if the path is valid
    if [ -f "$requirements_path" ]; then
        if [ "$flag_test" -eq 1 ]; then 
            echo "Path to the requirements file: $requirements_path"
        fi
        # If the notebook path is not valid, activate its flag for future processing
        flag_local_requirements=1
    else
        echo ""
        echo "------------------------------------"
        echo "The give path to the requirementes.txt is not valid: $requirements_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi

if [ -z "$docker_tag" ]; then
    # If no tag has been specified for the docker image, then the default tag will be used (the name of the notebook)
    docker_tag=$aux_docker_tag
    if [ "$flag_test" -eq 1 ]; then 
        echo "No tag has been specified for the docker image, therefore the default tag $docker_tag will be used."
    fi

    # If no version 
    if [ -z "$docker_hub_image" ] && [ -z "$versioned_docker_tag" ]; then
        # Get the notebook type of the configuration file
        if [[ "$config_path" = *'ZeroCostDL4Mic_notebooks'* ]]; then
            notebook_type='z'
        elif [[ "$config_path" = *'External_notebooks'* ]]; then
            notebook_type='e'
        elif [[ "$config_path" = *'Bespoke_notebooks'* ]]; then
            notebook_type='b'
        else
            # Is a custom configuration that is not in any of these notebook types
            # therefore the notebook type will be 'n'
            notebook_type='n'
        fi

        # In case the configuration file does not have a docker_hub_image attribute
        docker_tag=$(echo $docker_tag | tr '[:upper:]' '[:lower:]')
        docker_tag=henriqueslab/dl4miceverywhere:$docker_tag
        if [ -z "$dl4miceverywhere_version" ]; then
            docker_tag=$docker_tag-$notebook_type$notebook_version-d___
        else
            docker_tag=$docker_tag-$notebook_type$notebook_version-d$dl4miceverywhere_version
        fi
    else
        if [ -z "$versioned_docker_tag" ]; then
            # In case there is no versioned_docker_tag attribute, that meens that there is a docker_hub_image
            # In case the configuration file already has a docker_hub_image attribute
            docker_tag=henriqueslab/dl4miceverywhere:$docker_hub_image
        else
            # Otherwise, it means that versioned_docker_tag was provided and will be used
            docker_tag=henriqueslab/dl4miceverywhere:$versioned_docker_tag
        fi
    fi

    # Check if GPU has been requested and add it to the tag if necessary
    if [ "$flag_gpu" -eq 1 ]; then
        docker_tag=$docker_tag-gpu
    fi
else
    echo "The docker tag $docker_tag has been selected."
    echo ""
    echo "################################"
    echo ""
fi

if [ "$flag_test" -eq 1 ]; then
    echo ""
    echo "ubuntu_version: $ubuntu_version"
    echo "cuda_version: $cuda_version"
    echo "cudnn_version: $cudnn_version"
    echo "python_version: $python_version"
    echo "notebook_path: $notebook_path"
    echo "requirements_path: $requirements_path"
    echo "sections_to_remove: $sections_to_remove"
    echo "notebook_version: $notebook_version"
    echo "description: $description"
    echo "docker_tag: $docker_tag"
    echo ""
fi

notebook_name="$(basename "$notebook_path")"

# Local files, if included, need to be remocreated in same folder as the dockerfile,
# then they will be deleted
if [ "$flag_local_notebook" -eq 1 ]; then
    cp "$notebook_path" "$BASEDIR/notebook.ipynb"
    notebook_path=./notebook.ipynb
fi

if [ "$flag_local_requirements" -eq 1 ]; then
   cp "$requirements_path" "$BASEDIR/requirements.txt"
   requirements_path=./requirements.txt
fi

# Check if there is the errata in ~/.docker/config.json where credsStore should be credStore
if grep -q credsStore ~/.docker/config.json; then
    # Apparently, on MaxOS, it returns: 
    #   ERROR: failed to solve: error getting credentials - err: exit status 1, out: “ 
    # It can be solved by changing this argument in the configuration file (working also on Linux with this change).
    perl -pi -e "s/credsStore/credStore/g" ~/.docker/config.json 
fi

# Execute the pre building tests
/bin/bash "$BASEDIR/.tools/bash_tools/pre_build_test.sh" || exit 1

###
# Get what is the containerisation system that will be used
if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    # It shouldn't enter here, because at this point the .cache_preferences file
    # should be created. But just in case, Docker is the default containerisation sysyem.
    containerisation="Docker"
else
   containerisation=$(awk -F' : ' '$1 == "containerisation" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
fi
###

# Check if an image with that tag exists locally and ask if the user whants to replace it.
flag_build=0

# In case testing is chossing, the building is forced to be done, without questions
if [ "$flag_test" -eq 1 ]; then
    # In case of testing, the building is always done
    flag_build=2
else
    if [[ "$containerisation" == "Docker"* ]]; then
        # Check if there is a docker image with that tag locally
        if docker image inspect $docker_tag >/dev/null 2>&1; then
            # If so, ask the user with GUI or CLI if the user wants to use local image or replace it
            if [ "$flag_gui" -eq 1 ]; then 
                # If the GUI flag has been specified, show a window for ansewring local question
                flag_build=$(wish "$BASEDIR/.tools/tcl_tools/local_img_gui.tcl" $OSTYPE)
            else
                echo "Image exists locally. Do you want to build and replace the existing one?"
                select yn in "Yes" "No"; do
                    case $yn in
                        Yes ) flag_build=2; break;;
                        No ) flag_build=1; break;;
                    esac
                done
            fi
        fi

        # Check if flag_build is not 1 (docker image was not locally or the user wanted to replace it)
        if [ "$flag_build" -ne 1 ]; then
            # If so, check if there is a docker image with that tag on Docker Hub
            if docker manifest inspect "${docker_tag}" >/dev/null 2>&1; then
                # If so, check the architecture of running machine

                # Get the architecture of the machine
                local_arch=$(uname -m)

                # It should be amd64 or arm64
                if [ "$local_arch" == "x86_64" ]; then
                    local_arch="amd64"
                fi

                # Count the ocurrences of that architecture in the docker manifest of that image
                arch_count=$(docker manifest inspect "${docker_tag}" -v | grep 'architecture' | grep -c $local_arch)

                # Check if there was at least an ocurrence of that architecture
                if [ "$arch_count" -gt 0 ]; then
                    # In case the architecture is available

                    # First check if a version was specified, because in that case it can 
                    # only pull from docker hub
                    if [ "$flag_version_selected" -eq 1 ]; then
                        # If the version was specified
                        title="Download from Docker Hub"
                        message="You chose ${docker_tag}, the image will be downloaded from Docker Hub."
                        eval $(wish "$BASEDIR/.tools/tcl_tools/oneline_done_gui.tcl" "$title" "$message")
                        flag_build=3
                    else
                        # If the version was NOT specified
                        if [ "$flag_gui" -eq 1 ]; then 
                            # If the GUI flag has been specified, show a window for ansewring hub question
                            flag_build=$(wish "$BASEDIR/.tools/tcl_tools/hub_img_gui.tcl" "$OSTYPE")
                        else
                            echo "The image ${docker_tag} is already available on Docker Hub. Do you preffer to pull it (faster option) instead of building it?"
                            select yn in "Yes" "No"; do
                                case $yn in
                                    Yes ) flag_build=3; break;;
                                    No )  flag_build=2; break;;
                                esac
                            done
                        fi
                    fi

                    
                else
                    # In case the architecture is not available

                    # First check if a version was given  
                    if [ "$flag_version_selected" -eq 1 ]; then
                        # If the version was specified, throug an error that this version 
                        # could not be found on Docker Hub
                        title="Error: Image not avilable"
                        error_message="Selected version of the image is not available in Docker Hub for your computer. Please try another version or do not chose any."
                        if [ "$flag_gui" -eq 1 ]; then 
                            # If the GUI flag has been specified, show a window with the message
                            eval $(wish "$BASEDIR/.tools/tcl_tools/oneline_done_gui.tcl" "$title" "$error_message")
                        else
                            echo "$error_message"
                        fi
                        echo ""
                        echo "------------------------------------"
                        read -p "Press enter to close the terminal."
                        echo "------------------------------------" 
                        exit 1
                    else
                        # If the architecture is not available on Docker Hub and the user didn't 
                        # ask for a specific version, try to build it locally
                        flag_build=2
                    fi
                fi
            else
                # In case the image is NOT available on Docker Hub
                # First check if a version was given  
                if [ "$flag_version_selected" -eq 1 ]; then
                    # If the version was specified, throug an error that this version 
                    # could not be found on Docker Hub
                    title="Error: Image not avilable"
                    error_message="Selected version of the image is not available in Docker Hub for your computer. Please try another version or do not chose any."
                    if [ "$flag_gui" -eq 1 ]; then 
                        # If the GUI flag has been specified, show a window with the message
                        eval $(wish "$BASEDIR/.tools/tcl_tools/oneline_done_gui.tcl" "$title" "$error_message")
                    else
                        echo "$error_message"
                    fi
                    echo ""
                    echo "------------------------------------"
                    read -p "Press enter to close the terminal."
                    echo "------------------------------------" 
                    exit 1
                else
                    # If the architecture is not available on Docker Hub and the user didn't 
                    # ask for a specific version, try to build it locally
                    flag_build=2
                fi
            fi
        fi
    fi
fi

if [ "$flag_build" -eq 3 ]; then
    echo "The image will be pulled from Docker Hub."
elif [ "$flag_build" -eq 2 ]; then
    echo "The image will be built locally."
elif [ "$flag_build" -eq 1 ]; then
    echo "A local version of the image will be used."
else
    echo "SOMETHING WENT WRONG :("
fi

# If flag_build is 3 the pull the docker image from docker hub
if [ "$flag_build" -eq 3 ]; then
    # Pull the docker image
    docker pull "$docker_tag"
    DOCKER_OUT=$? # Gets if the docker image has been pulled
else
    # Build the docker image without GUI
    if [ "$flag_build" -eq 2 ]; then
        if [ "$flag_gpu" -eq 1 ]; then
            echo "To build the docker image, you need to provide root access by entering your password."
            echo "Otherwise, you can choose the option of getting the image from Docker Hub or follow"
            echo "the steps in our documentation."
            sudo docker build --file "$BASEDIR/Dockerfile.gpu" -t $docker_tag "$BASEDIR"\
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg CUDA_VERSION="${cuda_version}" \
                --build-arg CUDNN_VERSION="${cudnn_version}" \
                --build-arg flag_gpu="${flag_gpu}" \
                --build-arg PYTHON_VERSION="${python_version}" \
                --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
                --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
                --build-arg NOTEBOOK_NAME="${notebook_name}" \
                --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" \
                --build-arg CACHEBUST=$(date +%s)
        else
            echo "To build the docker image, you need to provide root access by entering your password."
            echo "Otherwise, you can choose the option of getting the image from Docker Hub or follow"
            echo "the steps in our documentation."
            sudo docker build --file "$BASEDIR/Dockerfile" -t $docker_tag "$BASEDIR"\
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg flag_gpu="${flag_gpu}" \
                --build-arg PYTHON_VERSION="${python_version}" \
                --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
                --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
                --build-arg NOTEBOOK_NAME="${notebook_name}" \
                --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" \
                --build-arg CACHEBUST=$(date +%s)
        fi

        DOCKER_OUT=$? # Gets if the docker image has been built
    else
        if [ "$flag_build" -eq 1 ]; then
            DOCKER_OUT=0 # In case that is already built, it is good to run
        else
            # build flag is still 0, an error ocurred
            echo ""
            echo "------------------------------------"
            echo "Error looking for existing docker image with the given tag:"
            echo "$docker_tag"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            # Close the terminal
            exit 1
        fi
    fi
fi

echo "Docker image correctly built/pulled"

# Execute the post building tests
/bin/bash "$BASEDIR/.tools/bash_tools/post_build_test.sh" || exit 1

sleep 3

# Local files, if included, need to be removed to avoid the overcrowding the folder
if [ "$flag_local_notebook" -eq 1 ]; then
   rm "$BASEDIR/notebook.ipynb"
fi

if [ "$flag_local_requirements" -eq 1 ]; then
   rm "$BASEDIR/requirements.txt"
fi

echo "Docker output:"
echo "$DOCKER_OUT"

# If it has been built, run the docker
if [ "$DOCKER_OUT" -eq 0 ]; then
    if [ $flag_test -eq 1 ]; then
        # In case ,testing is done, only building is required, exit before running
        exit 0
    fi

    # Choose an initial port
    if [ -z "$port_number" ]; then
        # In case user does not provide a port number, use the default 8888 port
        port=8888
    else
        # Else, use the port provided by the user
        port="$port_number"
    fi

    # Check if selected port is available if not try next one until finding a usable port. 
    if [[ "$OSTYPE" == "linux-gnu"* && "$(systemd-detect-virt)" == "wsl"* ]]; then        
        # Linux inside the Windows Subsystem for Linux needs to look differently to the ports
        while ( netstat -a | grep :$port &> /dev/null )
        do
            echo WARNING: Port $port is already allocated.
            port=$((port+1))
            if [ $port -gt 9000 ]; then
                # We want the port to be between 8000 and 9000
                port=8000
            sleep 1
            fi
        done
    else
        while ( lsof -i:$port &> /dev/null )
        do
            echo WARNING: Port $port is already allocated.
            port=$((port+1))
            if [ $port -gt 9000 ]; then
                # We want the port to be between 8000 and 9000
                port=8000
            sleep 1
            fi
        done
    fi
    echo SUCCESS: Port $port will be used.

    # Based on the openssl command and the base64 encoding, a 50 characters token is generated
    notebook_token=$(openssl rand -base64 50 | tr -dc 'a-zA-Z0-9')

    echo ""
    echo "################################################################################################################################"
    echo ""
    echo "   The generated token for the notebook is: $notebook_token"
    echo ""
    echo "################################################################################################################################"
    echo ""

    # Launch a subprocess to open the browser with the port in 10 seconds
    /bin/bash "$BASEDIR/.tools/bash_tools/open_browser.sh" 10 "http://localhost:$port/lab/tree/$notebook_name/?token=$notebook_token" &

    # Define the command that will be run when the docker image is launched
    docker_command="jupyter lab --ip='0.0.0.0' --port=$port --no-browser --allow-root --NotebookApp.token=$notebook_token; cp /home/docker_info.txt /home/results/docker_info.txt; cp /home/$notebook_name /home/results/$notebook_name;" 

    if [ "$flag_gpu" -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
        docker run -it --gpus all -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" --shm-size=256m "$docker_tag"  /bin/bash -c "$docker_command"
        echo -e "The command used to run this container has been:\n\tdocker run -it --gpus all -p $port:$port -v \"$data_path:/home/data\" -v \"$result_path:/home/results\" --shm-size=256m \"$docker_tag\"  /bin/bash -c \"$docker_command\"" >> "$result_path/docker_info.txt"
    else
        # Run the docker image without activating the GPU
        docker run -it -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" --shm-size=256m "$docker_tag"  /bin/bash -c "$docker_command"
        echo -e "The command used to run this container has been:\n\tdocker run -it -p $port:$port -v \"$data_path:/home/data\" -v \"$result_path:/home/results\" --shm-size=256m \"$docker_tag\"  /bin/bash -c \"$docker_command\"" >> "$result_path/docker_info.txt"
    fi


    # Read the variables from the yaml file
    echo -e "Used docker tag has been:\n\t$docker_tag" >> "$result_path/docker_info.txt"

    eval $(get_yaml_args_from_file "$BASEDIR/construct.yaml" "contruct_info_")
    echo -e "Used DL4MicEverywhere version has been:\n\t$contruct_info_version" >> "$result_path/docker_info.txt"

else
    echo ""
    echo "------------------------------------"
    echo "Error during the building of the docker image. Please check the logs."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1 
fi

# Close the terminal when user press enter
echo ""
echo "------------------------------------"
read -p "Press enter to close the terminal."
echo "------------------------------------" 
exit 1
