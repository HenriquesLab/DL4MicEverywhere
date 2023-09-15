#!/bin/bash
BASEDIR=$(dirname "$0")

# Function with the text to describe the usage of the bash script
usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path [-h|i|t|g] [-n notebook_path] [-r requirements_path] 

Create and deploy a Docker image for the ZeroCostDL4Mic notebooks.
Requires a local copy of the 'configuration.yaml' file and the 'data' folder.
Optionally you can also specify the paths to local copies of the notebook.ipynb and requirements.txt files.

Available options:

-h      Print this help and exit.
-c      Path to the configuration file 'configuration.yaml'.   
-d      Path to the data directory.
-g      Flag to specify if GPU should be used.
-n      Path to the notebook file 'notebook.ipynb'.
-r      Path to the requirements file 'requirements.txt'.
-i      Flag to indicate if you want to use a Graphic User Interface (GUI).
-t      Tag that will be added to the docker image.
-x      Flag to indicate if it is a test run.
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

# Function to describe the GUI based on zenity
zenity_gui() {
    # Mandatory arguments
    if [ -z $CONFIG_PATH ]; then
        config_output="-"
    else
        config_output=$CONFIG_PATH
    fi

    if [ -z $DATA_PATH ]; then
        data_output="-"
    else
        data_output=$DATA_PATH
    fi

    # Optional arguments
    if [ -z $GPU_FLAG_RC ]; then
        GPU_FLAG_RC=0
    fi

    if [ $GPU_FLAG_RC -eq 0 ]; then
        gpu_output="<span foreground='red'>No</span>" # "<b>No</No>"
    else
        gpu_output="<span foreground='green'>Yes</span>" #"<b>Yes</b>"
    fi

    if [ -z $NOTEBOOK_PATH ]; then
        notebook_output="-"
    else
        notebook_output=$NOTEBOOK_PATH
    fi

    if [ -z $REQUIREMENTS_PATH ]; then
        requirements_output="-"
    else
        requirements_output=$REQUIREMENTS_PATH
    fi

    req_config_text="\tConfiguration file: <b>${config_output}</b>\n\tData folder: <b>${data_output}</b>"
    extra_config_text="\t(optional) GPU: <b>${gpu_output}</b>\n\t(optional) Local notebook: <b>${notebook_output}</b>\n\t(optional) Local requirements: <b>${requirements_output}</b>"

    CONTINUE=$(zenity --info \
       --no-wrap \
       --title="Continue" \
       --text="<big><b>Welcome to DL4MicEverywhere!</b></big>\nUse the buttons below to select the configuration.yaml file and the data folder, these are <b>mandatory</b>.\nThe remaining arguments are optional, by default the GPU usage is set as <b>No</b>.\n The notebook.ipynb and requirements.txt files will be downloaded using the URLs in the configuration.yaml unless provided.\n\nCurrent arguments: \n${req_config_text}\n${extra_config_text}\n" \
       --ok-label="Cancel" \
       --extra-button="Configuration file" \
       --extra-button="Data folder" \
       --extra-button="GPU" \
       --extra-button="Local notebook" \
       --extra-button="Local requirements" \
       --extra-button="Done")
    CONTINUE_RC=$?
    if [ "$CONTINUE" = "Configuration file" ]; then
        config_window
    elif [ "$CONTINUE" = "Data folder" ]; then
        data_window
    elif [ "$CONTINUE" = "GPU" ]; then
        gpu_window
    elif [ "$CONTINUE" = "Local notebook" ]; then
        notebook_window
    elif [ "$CONTINUE" = "Local requirements" ]; then
        requirements_window
    elif [ "$CONTINUE" = "Done" ]; then
        if [ -z $CONFIG_PATH ]; then
            zenity --error \
                   --text="You need to specify a path to the configuration file."
            zenity_gui
        elif [ -z $DATA_PATH ]; then
            zenity --error \
                   --text="You need to specify a path to the data folder."
            zenity_gui
        else
            echo "Success!!"
        fi
    elif [ $CONTINUE_RC -eq 0 ] ||  [ $CONTINUE_RC -eq 1 ]; then
        echo "OUT"
        exit
    else
        echo "An unexpected error has occurred."
        exit
    fi
}

config_window() {
    CONFIG_PATH=$(zenity --file-selection \
        --title "Select configuration.yaml" \
        --file-filter="*.yaml")
    zenity_gui
}

data_window() {
    DATA_PATH=$(zenity --file-selection \
       --title "Select data directory" \
       --directory)
    zenity_gui
}

gpu_window() {
    zenity --question \
        --title="GPU?"\
        --text="Do you want GPU." \
        --ok-label="Yes" \
        --cancel-label="No"
    GPU_FLAG_RC=$?
    GPU_FLAG_RC=$(expr 1 - $GPU_FLAG_RC )
    zenity_gui
}

notebook_window() {
    NOTEBOOK_PATH=$(zenity --file-selection \
       --title "Select Notebook.ipynb" \
       --file-filter="*.ipynb")
    zenity_gui
}

requirements_window() {
    REQUIREMENTS_PATH=$(zenity --file-selection \
       --title "Select requirements.txt" \
       --file-filter="*.txt")
    zenity_gui
}

# Let's define the default values for the flags
gui_flag=0
gpu_flag=0
test_flag=0
local_notebook_flag=0
local_requirements_flag=0

# Let's parse the arguments
while getopts :hic:d:gn:r:t:x flag;do
    case $flag in 
        h)
            usage ;;
        i)
            gui_flag=1 ;;
        c)
            config_path="$OPTARG" ;;
        d)
            data_path="$OPTARG" ;;
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

echo ""

if [ $gui_flag -eq 0 ]; then 
    # If the GUI flag has not been specified
    echo "No GUI flag has been specified, therefore GUI will not be used."
else
    # If the GUI flag has been specified, run the function to show the GUI and read the arguments
    zenity_gui
    config_path="$CONFIG_PATH"
    data_path="$DATA_PATH"
    gpu_flag="$GPU_FLAG_RC"
    if [ ! -z $NOTEBOOK_PATH ]; then
        notebook_path="$NOTEBOOK_PATH"
    fi
    if [ ! -z $REQUIREMENTS_PATH ]; then
        requirements_path="$REQUIREMENTS_PATH" 
    fi
fi

echo ""

if [ -z "$config_path" ]; then 
    # If no configuration path has been specified, then exit with the error
    echo "No configuration.yaml file path has been specified, please make sure to use -c argument and give a value to it."
    exit 1
else
    # If a configuration path has been specified, check if it is valid
    if [[ -d $config_path ]]; then
        echo "Path to the configuration folder: $config_path"
        config_path=$config_path+"/configuration.yaml"
    elif [[ -f $config_path ]]; then
        echo "Path to the configuration file: $config_path"
    else
        echo "$config_path is not valid."
        exit 1
    fi
fi 

if [ -z "$data_path" ]; then 
    # If no data path has been specified, then exit with the error
    echo "No data path has been specified, please make sure to use -d argument and give a value to it."
    exit 1
else
    # If a data path has been specified, check if it is valid
    if [[ -d $data_path ]]; then
        echo "Path to the data: $data_path"
    else
        echo "$data_path is not valid."
        exit 1
    fi
fi 

# Prints if the GPU flag has been set
if [ "$gpu_flag" -eq 1 ]; then
    echo 'GPU will be allowed.'
else
    echo 'GPU is not allowed.'
fi

# Prints if the test flag has been set
if [ "$test_flag" -eq 1 ]; then
    echo 'TEST MODE: ON.'
else
    echo 'TEST MODE: OFF.'
fi

# Read the variables fro mthe yaml file
eval $(parse_yaml $config_path)

# Base image is selected based on the GPU selection
if [ "$gpu_flag" -eq 1 ]; then
   base_img="nvidia/cuda:${cuda_version}-base-ubuntu${ubuntu_version}"
else
   base_img="ubuntu:${ubuntu_version}"
fi

if [ -z "$notebook_path" ]; then
    # If no local notebook path has been specified, then the URL from the configuration file will be used
    notebook_path="${notebook_url}"
    # For the docker's tag if not specified
    aux_docker_tag="$(basename $notebook_path .ipynb?raw=true)"
    echo "No notebook has been specified, therefore the notebook url specified on 'configuration.yaml' will be used."
else
    # Otherwise check if the path is valid
    # For the docker's tag if not specified
    aux_docker_tag="$(basename $notebook_path .ipynb)"
    if [ -f "$notebook_path" ]; then
        echo "Path to the notebook: $notebook_path"
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
    echo "No requirements file has been specified, therefore the requirements url specified on 'configuration.yaml' will be used."
else
    # Otherwise check if the path is valid
    if [ -f "$requirements_path" ]; then
        echo "Path to the requirements file: $requirements_path"
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
    echo "No tag has been specified for the docker image, therefore the default tag $docker_tag will be used."
fi
docker_tag=$(echo $docker_tag | tr '[:upper:]' '[:lower:]')

echo ""
echo "base_img: $base_img"
echo "python_version: $python_version"
echo "notebook_path: $notebook_path"
echo "requirements_path: $requirements_path"
echo "sections_to_remove: $sections_to_remove"
echo "docker_tag: $docker_tag"
echo ""

notebook_name="$(basename "$notebook_path" ?raw=true)"

# Local files, if included, need to be remocreated in same folder as the dockerfile,
# then they will be deleted
if [ "$local_notebook_flag" -eq 1 ]; then
   cp $notebook_path $BASEDIR/notebook.ipynb
   notebook_path=./notebook.ipynb
fi

if [ "$local_requirements_flag" -eq 1 ]; then
   cp $notebook_path $BASEDIR/requirements.txt
   requirements_path=./requirements.txt
fi

# Check if there is the errata in ~/.docker/config.json where credsStore should be credStore
if grep -q credsStore ~/.docker/config.json; then
    # Apparently, on MaxOS, it returns: 
    #   ERROR: failed to solve: error getting credentials - err: exit status 1, out: “ 
    # It can be solved by changing this argument in the configuration file (working also on Linux with this change).
    perl -pi -e "s/credsStore/credStore/g" ~/.docker/config.json 
fi

if [ -z "$gui_flag" ]; then 
  # Build the docker image without GUI
  docker build $BASEDIR --no-cache  -t $docker_tag \
        --build-arg BASE_IMAGE="${base_img}" \
        --build-arg GPU_FLAG="${gpu_flag}" \
        --build-arg PYTHON_VERSION="${python_version}" \
        --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
        --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
        --build-arg NOTEBOOK_NAME="${notebook_name}" \
        --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}"
else
  # Build the docker image, using the GUI and showing a progess window
  docker build $BASEDIR --no-cache  -t $docker_tag \
        --build-arg BASE_IMAGE="${base_img}" \
        --build-arg GPU_FLAG="${gpu_flag}" \
        --build-arg PYTHON_VERSION="${python_version}" \
        --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
        --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
        --build-arg NOTEBOOK_NAME="${notebook_name}" \
        --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" # | zenity --progress --title "Building the image" --text "The docker is building..."
fi
DOCKER_OUT=$? # Gets if the docker image has been built

# Local files, if included, need to be removed to avoid the generation of many files
if [ "$local_notebook_flag" -eq 1 ]; then
   rm $BASEDIR/notebook.ipynb
fi

if [ "$local_requirements_flag" -eq 1 ]; then
   rm $BASEDIR/requirements.txt
fi

# If it has been built, run the docker
if [ "$DOCKER_OUT" -eq 0 ]; then
    if [ $test_flag -eq 1 ]; then
        exit 0
    fi
    if [ "$gpu_flag" -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
        docker run -it  --gpus all -p 8888:8888 -v $data_path:/home/dataset $docker_tag
    else
        # Run the docker image without activating the GPU
        docker run -it  -p 8888:8888 -v $data_path:/home/dataset $docker_tag
    fi
else
    echo "The docker image has not been built."
    if [ "$test_flag" -eq 1 ]; then
        exit 1
    fi
fi
exit 1