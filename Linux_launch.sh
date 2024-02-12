#!/bin/bash
BASEDIR=$(dirname "$(readlink -f "$0")")
            
# Run pre_launch_test.sh, stop if it fails
/bin/bash $BASEDIR/.tools/bash_tools/pre_launch_test.sh || exit 1

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
            echo "$variable_name parameter is not specified on the configuration yaml."
            # Close the terminal
            exit 1
        fi
    else
        rename_parsed_argument $variable_name
    fi
}

function cache_gui {
    echo "data_path : $1
result_path : $2
selected_folder : $3
selected_notebook : $4
config_path : $5
notebook_path : $6
requirements_path : $7
gpu_flag : $8
tag : $9" > $BASEDIR/.tools/.cache_gui
}

# Function to parse and read the configuration yaml file
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  "$1" |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      value = $3;

      # Remove inline comments only if they are at the beginning of a line or after whitespace
      gsub(/[[:space:]]#.*/, "", value);
      
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, value);
      }
   }'
}

# Let's define the default values for the flags
gpu_flag=0
test_flag=0
local_notebook_flag=0
local_requirements_flag=0

# Let's parse the arguments
while getopts :hc:d:o:gn:r:t:x flag;do
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
                gpu_flag=1
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
        x)
            test_flag=1 ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "Try bash ./launch.sh -h for more information."
            # Close the terminal
            exit 1 ;;
    esac
done

# If no arguments are provided, set the GUI flag
if [ $# -eq 0 ]; then
    gui_flag=1
else 
    gui_flag=0
fi

# Check if test mode is active
if [ "$test_flag" -eq 1 ]; then
    echo 'Test mode is enabled.'
fi

if [ $gui_flag -eq 0 ]; then 
    # If GUI is not requested
    if [ "$test_flag" -eq 1 ]; then
        echo "GUI is not requested, proceeding without GUI."
    fi
else
    # If the GUI flag has been specified, run the function to show the GUI and read the arguments
    gui_arguments=$(wish $BASEDIR/.tools/tcl_tools/main_gui.tcl $BASEDIR $OSTYPE)

    if [ -z "$gui_arguments" ]; then
        # Close the terminal
        exit 1
    fi

    IFS=$'\n' read -d '' -r -a strarr <<<"$gui_arguments"

    advanced_options=${strarr[0]}

    if [ $advanced_options -eq 0 ]; then
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"
        selectedFolder="${strarr[3]}"
        selectedNotebook="${strarr[4]}"
        gpu_flag="${strarr[5]}"
        tag_aux="${strarr[6]}"

        cache_gui "$data_path" "$result_path" "$selectedFolder" "$selectedNotebook" "" "" "" "$gpu_flag" "$tag_aux"

        if [ "$tag_aux" != "-" ]; then
            docker_tag="$tag_aux"
        fi

        config_path=$BASEDIR/notebooks/$selectedFolder/$selectedNotebook/configuration.yaml
    else
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"

        config_path="${strarr[3]}"

        notebook_aux="${strarr[4]}"
        requirements_aux="${strarr[5]}"
        
        gpu_flag="${strarr[6]}"
        tag_aux="${strarr[7]}"

        cache_gui "$data_path" "$result_path" "" "" "$config_path" "$notebook_aux" "$requirements_aux" "$gpu_flag" "$tag_aux"

        if [ "$notebook_aux" != "-" ]; then
            notebook_path="$notebook_aux"
        fi
        if [ "$requirements_aux" != "-" ]; then
            requirements_path="$requirements_aux"
        fi
        if [ "$tag_aux" != "-" ]; then
            docker_tag="$tag_aux"
        fi
    fi
fi

if [ -z "$config_path" ]; then 
    # If no configuration path has been specified, then exit with the error
    echo "No path to the configuration.yaml file has been specified, please make sure to use -c argument and give a value to it."
    
    # Close the terminal
    exit 1
else
    # If a configuration path has been specified, check if it is valid
    if [[ -d "$config_path" ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
        config_path="$config_path/configuration.yaml"
    elif [[ -f "$config_path" ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
    else
        echo "$config_path is not valid."
        
        # Close the terminal
        exit 1
    fi
fi 

if [ -z "$data_path" ]; then 
    # Exit with an error if no data path is specified
    echo "Please specify a path to the data folder using the -d argument."
    
        # Close the terminal
        exit 1
else
    # Validate the specified data path
    if [[ -d "$data_path" ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Data path: $data_path"
        fi
    else
        echo "The specified data path $data_path is not valid."
        
        # Close the terminal
        exit 1
    fi
fi 

if [ -z "$result_path" ]; then 
    # Exit with an error if no result path is specified
    echo "Please specify a path to the output folder using the -o argument."
    
    # Close the terminal
    exit 1
else
    # Validate the specified result path
    if [[ -d "$result_path" ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Result path: $result_path"
        fi
    else
        echo "The specified result path $result_path is not valid."
        
        # Close the terminal
        exit 1
    fi
fi 

if [ "$test_flag" -eq 1 ]; then
    # If the test flag is set, print whether the GPU flag has been set
    if [ "$gpu_flag" -eq 1 ]; then
        echo 'GPU usage is enabled.'
    else
        echo 'GPU usage is disabled.'
    fi
fi

# Read the variables from the yaml file
eval $(parse_yaml "$config_path")

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

if [ -z "$notebook_path" ]; then
    # Use the URL from the configuration file if no local notebook path is specified
    notebook_path="${notebook_url}"
    # Set the docker's tag if not specified
    if [ -z "$docker_hub_image" ]; then
        aux_docker_tag="$(basename "$notebook_path" .ipynb)"
    else
        aux_docker_tag="${docker_hub_image}"
    fi

    if [ "$test_flag" -eq 1 ]; then
        echo "Since no notebook was specified, the notebook URL from 'configuration.yaml' will be used."
    fi
else
    # Otherwise check if the path is valid
    # For the docker's tag if not specified
    if [ -z "$docker_hub_image" ]; then
        aux_docker_tag="$(basename "$notebook_path" .ipynb)"
    else
        aux_docker_tag="${docker_hub_image}"
    fi

    if [ -f "$notebook_path" ]; then
    
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the notebook: $notebook_path"
        fi
        
        # If the notebook path is not valid, activate its flag for future processing
        local_notebook_flag=1
    else
        echo "$notebook_path does not exist."
        
        # Close the terminal
        exit 1
    fi
fi

if [ -z "$requirements_path" ]; then
    # If no local requirements path has been specified, then the URL from the configuration file will be used
    requirements_path="${requirements_url}"
    local_requirements_flag=0
    if [ "$test_flag" -eq 1 ]; then 
        echo "No requirements file has been specified, therefore the requirements url specified on 'configuration.yaml' will be used."
    fi
else
    # Otherwise check if the path is valid
    if [ -f "$requirements_path" ]; then
        if [ "$test_flag" -eq 1 ]; then 
            echo "Path to the requirements file: $requirements_path"
        fi
        # If the notebook path is not valid, activate its flag for future processing
        local_requirements_flag=1
    else
        echo "$requirements_path does not exist."
        
        # Close the terminal
        exit 1
    fi
fi

if [ -z "$docker_tag" ]; then
    # If no tag has been specified for the docker image, then the default tag will be used (the name of the notebook)
    docker_tag=$aux_docker_tag

    if [ "$test_flag" -eq 1 ]; then 
        echo "No tag has been specified for the docker image, therefore the default tag $docker_tag will be used."
    fi

    if [ -z "$docker_hub_image" ]; then
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
        if [ "$gpu_flag" -eq 1 ]; then
            docker_tag=$docker_tag-gpu
        fi
    else
        # In case the configuration file already has a docker_hub_image attribute
        docker_tag=henriqueslab/dl4miceverywhere:$docker_hub_image
        if [ "$gpu_flag" -eq 1 ]; then
            docker_tag=$docker_tag-gpu
        fi
    fi

fi


# Set the docker's tag
if [ "$test_flag" -eq 1 ]; then
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
if [ "$local_notebook_flag" -eq 1 ]; then
    cp "$notebook_path" "$BASEDIR/notebook.ipynb"
    notebook_path=./notebook.ipynb
fi

if [ "$local_requirements_flag" -eq 1 ]; then
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
/bin/bash $BASEDIR/.tools/bash_tools/pre_build_test.sh || exit 1

# Check if an image with that tag exists locally and ask if the user whants to replace it.
build_flag=0

# In case testing is chossing, the building is forced to be done, without questions
if [ "$test_flag" -eq 1 ]; then
    # In case of testing, the building is always done
    build_flag=2
else
    if docker image inspect $docker_tag >/dev/null 2>&1; then
        if [ "$gui_flag" -eq 1 ]; then 
            # If the GUI flag has been specified, show a window for ansewring local question
            build_flag=$(wish $BASEDIR/.tools/tcl_tools/local_img_gui.tcl)
        else
            echo "Image exists locally. Do you want to build and replace the existing one?"
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) build_flag=2; break;;
                    No ) build_flag=1; break;;
                esac
            done
        fi
    fi

    
    if [ "$build_flag" -ne 1 ]; then
        # In case the local image option has not been selected

        if docker manifest inspect "${docker_tag}" >/dev/null 2>&1; then
            # In case the image is available on docker hub

            # Get the architecture of the machine
            local_arch=$(uname -m)

            if [ "$local_arch" == "x86_64" ]; then
                local_arch="amd64"
            fi

            # Count the ocurrences of that architecture in the docker manifest of that image
            arch_count=$(docker manifest inspect "${docker_tag}" -v | grep 'architecture' | grep -c $local_arch)

            if [ "$arch_count" -gt 0 ]; then
                # In case the architecture is available
                if [ "$gui_flag" -eq 1 ]; then 
                    # If the GUI flag has been specified, show a window for ansewring hub question
                    build_flag=$(wish $BASEDIR/.tools/tcl_tools/hub_img_gui.tcl)
                else
                    echo "The image ${docker_tag} is already available on docker hub. Do you preffer to pull it (faster option) instead of building it?"
                    select yn in "Yes" "No"; do
                        case $yn in
                            Yes ) build_flag=3; break;;
                            No )  build_flag=2; break;;
                        esac
                    done
                fi
            else
                # In case the architecture is not available
                build_flag=2
            fi
        else
            build_flag=2
        fi
    fi
fi

# Pull the docker image from docker hub
if [ "$build_flag" -eq 3 ]; then
    docker pull "$docker_tag"
    DOCKER_OUT=$? # Gets if the docker image has been pulled
else
    # Build the docker image without GUI
    if [ "$build_flag" -eq 2 ]; then
        if [ "$gpu_flag" -eq 1 ]; then
            echo "To build the docker image, you need to provide root access by entering your password."
            echo "Otherwise, you can choose the option of getting the image from Docker Hub or follow"
            echo "the steps in our documentation."
            sudo docker build --file $BASEDIR/Dockerfile.gpu -t $docker_tag $BASEDIR\
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg CUDA_VERSION="${cuda_version}" \
                --build-arg CUDNN_VERSION="${cudnn_version}" \
                --build-arg GPU_FLAG="${gpu_flag}" \
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
            sudo docker build --file $BASEDIR/Dockerfile -t $docker_tag $BASEDIR\
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg GPU_FLAG="${gpu_flag}" \
                --build-arg PYTHON_VERSION="${python_version}" \
                --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
                --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
                --build-arg NOTEBOOK_NAME="${notebook_name}" \
                --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" \
                --build-arg CACHEBUST=$(date +%s)
        fi

        DOCKER_OUT=$? # Gets if the docker image has been built
    else
        if [ "$build_flag" -eq 1 ]; then
            DOCKER_OUT=0 # In case that is already built, it is good to run
        else
            # build flag is still 0, an error ocurred
            echo "Error building the docker image"
            
            # Close the terminal
            exit 1
        fi
    fi
fi

# Execute the post building tests
/bin/bash $BASEDIR/.tools/bash_tools/post_build_test.sh || exit 1

# Local files, if included, need to be removed to avoid the overcrowding the folder
if [ "$local_notebook_flag" -eq 1 ]; then
   rm $BASEDIR/notebook.ipynb
fi

if [ "$local_requirements_flag" -eq 1 ]; then
   rm $BASEDIR/requirements.txt
fi

# If it has been built, run the docker
if [ "$DOCKER_OUT" -eq 0 ]; then
    if [ $test_flag -eq 1 ]; then
        # In case ,testing is done, only building is required, exit before running
        exit 0
    fi

    # Find a usable port
    port=8888
    while ( lsof -i:$port &> /dev/null )
    do
        port=$((port+1))
        if [ $port -gt 9000 ]; then
            # We want the port to be between 8000 and 9000
            port=8000
        fi
    done

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
    /bin/bash $BASEDIR/.tools/bash_tools/open_browser.sh http://localhost:$port/lab/tree/$notebook_name/?token=$notebook_token &

    # Define the command that will be run when the docker image is launched
    docker_command="jupyter lab --ip='0.0.0.0' --port=$port --no-browser --allow-root --NotebookApp.token=$notebook_token; cp /home/docker_info.txt /home/results/docker_info.txt; cp /home/$notebook_name /home/results/$notebook_name;" 

    if [ "$gpu_flag" -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
        docker run -it --gpus all -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" "$docker_tag"  /bin/bash -c "$docker_command"
    else
        # Run the docker image without activating the GPU
        docker run -it -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" "$docker_tag"  /bin/bash -c "$docker_command"
    fi
else
    echo "The docker image has not been built."
    if [ "$test_flag" -eq 1 ]; then
        # Close the terminal
        exit 1
    fi
fi

# Close the terminal
exit 1