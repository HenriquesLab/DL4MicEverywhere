#!/bin/bash
BASEDIR=$(dirname "$0")

# Check if script is run as root but only on Unix-like systems
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (by using sudo). Otherwise docker won't work properly."
    exit
  fi
fi

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
 -i      Flag to indicate if you want to use a Graphic User Interface (GUI). (optional)
 -t      Tag to be added to the docker image during building. (optional)
 -x      Flag to indicate if it is a test run. This allows for the printing of useful debugging information. (optional)

Code example:
    $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path -o output_path [-h|i|t|g] [-n notebook_path] [-r requirements_path] 

EOF
  exit
}

# Function to parse and read the configuration yaml file
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Let's define the default values for the flags
gui_flag=0
gpu_flag=0
test_flag=0
local_notebook_flag=0
local_requirements_flag=0

# Let's parse the arguments
while getopts :hic:d:o:gn:r:t:x flag;do
    case $flag in 
        h)
            usage ;;
        i)
            gui_flag=1 ;;
        c)
            config_path="$OPTARG" ;;
        d)
            data_path="$OPTARG" ;;
        o)
            result_path="$OPTARG" ;;
        g)
            gpu_flag=1 ;;
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
            exit 1 ;;
    esac
done
    

# Let's check the arguments

if [ $# -eq 0 ]; then
    echo "No arguments provided."
    echo "You can start the script with -h for help, -c for configuration, or -i for showing a Graphic User Interface."
    exit 1
fi

# Prints if the test flag has been set
if [ "$test_flag" -eq 1 ]; then
    echo 'Test mode ACTIVATED.'
fi

if [ $gui_flag -eq 0 ]; then 
    # If the GUI flag has not been specified
    if [ "$test_flag" -eq 1 ]; then
        echo "No GUI flag has been specified, therefore GUI will not be used."
    fi
else
    # If the GUI flag has been specified, run the function to show the GUI and read the arguments
    notebook_list=$(ls ./notebooks)
    gui_arguments=$(wish .tools/main_gui.tcl $notebook_list)

    if [ -z "$gui_arguments" ]; then
        exit 1
    fi

    IFS=$'\n' read -d '' -r -a strarr <<<"$gui_arguments"
    
    advanced_options=${strarr[0]}

    if [ $advanced_options -eq 0 ]; then
        data_path=${strarr[1]}
        result_path=${strarr[2]}
        selectedFolder=${strarr[3]}
        selectedNotebook=${strarr[4]}

        config_path=$BASEDIR/notebooks/$selectedFolder/$selectedNotebook/configuration.yaml
    else
        data_path=${strarr[1]}
        result_path=${strarr[2]}

        config_path=${strarr[3]}

        notebook_aux=${strarr[4]}
        requirements_aux=${strarr[5]}
        
        gpu_flag=${strarr[6]}
        tag_aux=${strarr[7]}

        if [ $notebook_aux != "-" ]; then
            notebook_path="$notebook_aux"
        fi
        if [ $requirements_aux != "-" ]; then
            requirements_path="$requirements_aux" 
        fi
        if [ $tag_aux != "-" ]; then
            docker_tag="$tag_aux" 
        fi
    fi
fi

if [ -z "$config_path" ]; then 
    # If no configuration path has been specified, then exit with the error
    echo "No path to the configuration.yaml file has been specified, please make sure to use -c argument and give a value to it."
    exit 1
else
    # If a configuration path has been specified, check if it is valid
    if [[ -d $config_path ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
        config_path=$config_path+"/configuration.yaml"
    elif [[ -f $config_path ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
    else
        echo "$config_path is not valid."
        exit 1
    fi
fi 

if [ -z "$data_path" ]; then 
    # Exit with an error if no data path is specified
    echo "Please specify a path to the data folder using the -d argument."
    exit 1
else
    # Validate the specified data path
    if [[ -d $data_path ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Data path: $data_path"
        fi
    else
        echo "The specified data path $data_path is not valid."
        exit 1
    fi
fi 

if [ -z "$result_path" ]; then 
    # Exit with an error if no result path is specified
    echo "Please specify a path to the output folder using the -o argument."
    exit 1
else
    # Validate the specified result path
    if [[ -d $result_path ]]; then
        if [ "$test_flag" -eq 1 ]; then
            echo "Result path: $result_path"
        fi
    else
        echo "The specified result path $result_path is not valid."
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
eval $(parse_yaml $config_path)

# Base image is selected based on the GPU selection
if [ "$gpu_flag" -eq 1 ]; then
   base_img="nvidia/cuda:${cuda_version}-base-ubuntu${ubuntu_version}"
else
   base_img="ubuntu:${ubuntu_version}"
fi

if [ -z "$notebook_path" ]; then
    # Use the URL from the configuration file if no local notebook path is specified
    notebook_path="${notebook_url}"
    # Set the docker's tag if not specified
    aux_docker_tag="$(basename $notebook_path .ipynb?raw=true)"

    if [ "$test_flag" -eq 1 ]; then
        echo "Since no notebook was specified, the notebook URL from 'configuration.yaml' will be used."
    fi

else
    # Otherwise check if the path is valid
    # For the docker's tag if not specified
    aux_docker_tag="$(basename $notebook_path .ipynb)"
    if [ -f "$notebook_path" ]; then
    
        if [ "$test_flag" -eq 1 ]; then
            echo "Path to the notebook: $notebook_path"
        fi
        
        # If the notebook path is not valid, activate its flag for future processing
        local_notebook_flag=1
    else
        echo "$notebook_path does not exist."
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
        exit 1
    fi
fi

if [ -z "$docker_tag" ]; then
    # If no tag has been specified for the docker image, then the default tag will be used (the name of the notebook)
    docker_tag=$aux_docker_tag

    if [ "$test_flag" -eq 1 ]; then 
        echo "No tag has been specified for the docker image, therefore the default tag $docker_tag will be used."
    fi
fi

docker_tag=$(echo $docker_tag | tr '[:upper:]' '[:lower:]')

if [ "$test_flag" -eq 1 ]; then
    echo ""
    echo "base_img: $base_img"
    echo "python_version: $python_version"
    echo "notebook_path: $notebook_path"
    echo "requirements_path: $requirements_path"
    echo "sections_to_remove: $sections_to_remove"
    echo "version: $version"
    echo "description: $description"
    echo "docker_tag: $docker_tag"
    echo ""
fi

notebook_name="$(basename "$notebook_path" ?raw=true)"

# Local files, if included, need to be remocreated in same folder as the dockerfile,
# then they will be deleted
if [ "$local_notebook_flag" -eq 1 ]; then
    cp $notebook_path $BASEDIR/notebook.ipynb
    notebook_path=./notebook.ipynb
fi

if [ "$local_requirements_flag" -eq 1 ]; then
   cp $requirements_path $BASEDIR/requirements.txt
   requirements_path=./requirements.txt
fi

# Check if docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker."
    exit
fi

# Check if there is the errata in ~/.docker/config.json where credsStore should be credStore
if grep -q credsStore ~/.docker/config.json; then
    # Apparently, on MaxOS, it returns: 
    #   ERROR: failed to solve: error getting credentials - err: exit status 1, out: “ 
    # It can be solved by changing this argument in the configuration file (working also on Linux with this change).
    perl -pi -e "s/credsStore/credStore/g" ~/.docker/config.json 
fi

# Execute the pre building tests
/bin/bash .tools/pre_build_test.sh

# Check if an image with that tag exists locally and ask if the user whants to replace it.
build_flag=0

# In case testing is chossing, the building is forced to be done, without questions
if [ $test_flag -eq 0 ]; then
    if docker image inspect $docker_tag >/dev/null 2>&1; then
        if [ $gui_flag -eq 1 ]; then 
            # If the GUI flag has been specified, show a window for ansewring local question
            build_flag=$(wish .tools/local_img_gui.tcl)
        else
            echo "Image exists locally. Do you want to build and replace the existing one?"
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) build_flag=2; break;;
                    No ) build_flag=1; break;;
                esac
            done
        fi
    else
        # In case the image is not locally, check if it is on docker hub
        possible_dockerhub_tag=henriqueslab/dl4miceverywhere:$docker_tag-$version
        if [ "$gpu_flag" -eq 1 ]; then
            possible_dockerhub_tag=$possible_dockerhub_tag-gpu
        fi

        if docker manifest inspect "${possible_dockerhub_tag}" >/dev/null 2>&1; then
            if [ $gui_flag -eq 1 ]; then 
                # If the GUI flag has been specified, show a window for ansewring hub question
                build_flag=$(wish .tools/hub_img_gui.tcl)
            else
                echo "The image ${possible_dockerhub_tag} is already available on docker hub. Do you preffer to pull it (faster option) instead of building it?"
                select yn in "Yes" "No"; do
                    case $yn in
                        Yes ) build_flag=3; break;;
                        No ) break;;
                    esac
                done
            fi
        fi
    fi 
fi

# Pull the docker image from docker hub
if [ "$build_flag" -eq 3 ]; then
    docker pull "${possible_dockerhub_tag}"
    DOCKER_OUT=$? # Gets if the docker image has been pulled
else
    # Build the docker image without GUI
    if [ "$build_flag" -eq 2 ]; then
        docker build $BASEDIR --no-cache -t $docker_tag \
            --build-arg BASE_IMAGE="${base_img}" \
            --build-arg GPU_FLAG="${gpu_flag}" \
            --build-arg PYTHON_VERSION="${python_version}" \
            --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
            --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
            --build-arg NOTEBOOK_NAME="${notebook_name}" \
            --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}"

        DOCKER_OUT=$? # Gets if the docker image has been built
    else
        if [ "$build_flag" -eq 1 ]; then
            DOCKER_OUT=0 # In case that is already built, it is good to run
        else
            # build flag is still 0, an error ocurred
            exit 1
        fi
    fi
fi

# Execute the post building tests
/bin/bash .tools/post_build_test.sh

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

    if [ "$gpu_flag" -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
        docker run -it --gpus all -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" "$docker_tag:latest" jupyter lab "${notebook_name}" --ip='0.0.0.0' --port=$port --no-browser --allow-root
    else
        # Run the docker image without activating the GPU
        docker run -it -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" "$docker_tag:latest" jupyter lab "${notebook_name}" --ip='0.0.0.0' --port=$port --no-browser --allow-root
    fi
else
    echo "The docker image has not been built."
    if [ "$test_flag" -eq 1 ]; then
        exit 1
    fi
fi