#!/bin/bash
BASEDIR=$(dirname "$0")

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] -n notebook_name -d dataset_path

Script description here.

Available options:

-h, --help              Print this help and exit
-c, --config_path       Path to the configuration file 'configuration.yaml'     
-d, --data_path         Path to the data directory
-g, --gpu               Flag to specify if GPU should be used
-n, --notebook_path     Path to the notebook (it needs to be relative from where the dockerfile is located)
-r, --requirements_path Path to the requirements file (it needs to be relative from where the dockerfile is located)
EOF
  exit
}

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
       --text="<big><b>Welcome to DL4Mic_everywhere!</b></big>\nBellow you have the buttons to add the data you need to provide in order to run the docker and the notebook. The paths to both\nthe configuration yaml file and data folder are mandatory. The rest of them are optional, by default the GPU usage is set as <b>No</b>\nand if no local paths are specified to the notebook and requirementes files, they will be downloaded using the URLs from\nthe configuration yaml file.\n\nValues of the arguments: \n${req_config_text}\n${extra_config_text}\n" \
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
            echo "Succes!!"
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
       --title "Select data_path" \
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

while getopts :hx:c:d:g:n:r: flag;do
   case $flag in 
      h)
        usage ;;
      x)
        gui_flag="$OPTARG" ;;
      c)
        config_path="$OPTARG" ;;
      d)
        data_path="$OPTARG" ;;
      g)
        gpu_flag="$OPTARG" ;;
      n)
        notebook_path="$OPTARG" ;;
      r)
        requirements_path="$OPTARG" ;;
      \?)
        echo "Invalid option: -$OPTARG"
        echo "Try bash ./test.sh -h for more information."
        exit 1 ;;
   esac
done

echo ""

if [ -z "$gui_flag" ]; then 
   echo "No GUI flag has been specified, therefore GUI will not be used."
else
  zenity_gui
  config_path="$CONFIG_PATH"
  data_path="$DATA_PATH"
  gpu_flag="$GPU_FLAG_RC"
  if [ -z $NOTEBOOK_PATH ]; then
    notebook_path="$NOTEBOOK_PATH"
  fi
  if [ -z $REQUIREMENTS_PATH ]; then
      requirements_path="$REQUIREMENTS_PATH" 
  fi
fi

echo ""

if [ -z "$config_path" ]; then 
   echo "No configuration path has been specified, please make sure to use -c --config_path argument and give a value to it."
   exit 1
else
   if [[ -d $config_path ]]; then
      echo "Path to the data folder: $config_path"
      config_path=$config_path+"/configuration.yaml"
   elif [[ -f $config_path ]]; then
      echo "Path to the data file: $config_path"
   else
      echo "$config_path is not valid."
      exit 1
   fi
fi 

if [ -z "$data_path" ]; then 
   echo "No data path has been specified, please make sure to use -d --data_path argument and give a value to it."
   exit 1
else
   echo "Path to the data: $data_path"
fi 

if [ -z "$gpu_flag" ]; then 
   echo "No GPU flag has been specified, therefore GPU will not be used."
   gpu_flag=0
else
   if [ "$gpu_flag" -eq 1 ]; then
      echo 'GPU will be allowed.'
   else
      echo 'GPU is not allowed.'
   fi
fi

# Read the variables fro mthe yaml file
eval $(parse_yaml $config_path)

if [ "$gpu_flag" -eq 1 ]; then
   base_img="nvidia/cuda:${cuda_version}-base-ubuntu${ubuntu_version}"
else
   base_img="ubuntu:${ubuntu_version}"
fi


if [ -z "$notebook_path" ]; then
   notebook_path="${notebook_url}"
   echo "No notebook has been specified, therefore the notebook url specified on 'configuration.yaml' will be used."
else
   if [ - d $notebook_path ]; then
      echo "Path to the notebook: $notebook_path"
   else
      echo "$notebook_path is not valid. REMEMBER: the path needs to be relative from where the dockerfile is located."
      exit 1
   fi
fi

if [ -z "$requirements_path" ]; then
   requirements_path="${requirements_url}"
   echo "No requirements file has been specified, therefore the requirements url specified on 'configuration.yaml' will be used."
else
   if [ - d $requirements_path ]; then
      echo "Path to the requirements file: $requirements_path"
   else
      echo "$requirements_path is not valid. REMEMBER: the path needs to be relative from where the dockerfile is located."
      exit 1
   fi
fi

echo ""
echo "base_img: $base_img"
echo "python_version: $python_version"
echo "notebook_path: $notebook_path"
echo "requirements_path: $requirements_path"
echo "sections_to_remove: $sections_to_remove"
echo ""

# Check if there is the errata in ~/.docker/config.json where credsStore should be credStore
if grep -q credsStore ~/.docker/config.json; then
    # Apparently, on MaxOS, it returns: 
    #   ERROR: failed to solve: error getting credentials - err: exit status 1, out: “ 
    # It can be solved by changing this argument in the configuration file (working also on Linux with this change).
    perl -pi -e "s/credsStore/credStore/g" ~/.docker/config.json 
fi

if [ -z "$gui_flag" ]; then 
  # Build the docker image without GUI
  docker build $BASEDIR --no-cache -t "notebook_dl4mic" \
        --build-arg BASE_IMAGE="${base_img}" \
        --build-arg GPU_FLAG="${gpu_flag}" \
        --build-arg PYTHON_VERSION="${python_version}" \
        --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
        --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
        --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}"
else
  # Build the docker image, using the GUI and showing a progess window
  docker build $BASEDIR --no-cache -t "notebook_dl4mic" \
        --build-arg BASE_IMAGE="${base_img}" \
        --build-arg GPU_FLAG="${gpu_flag}" \
        --build-arg PYTHON_VERSION="${python_version}" \
        --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
        --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
        --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" | zenity --progress --title "Building the image" --text "The docker is building..."
fi
DOCKER_OUT=$? # Gets if the docker image has been built

# If it has been built, run the docker
if [ $DOCKER_OUT -eq 0 ]; then
    if [ $gpu_flag -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
       docker run -it --gpus all -p 8888:8888 -v $data_path:/home/dataset notebook_dl4mic
    else
        # Run the docker image without activating the GPU
       docker run -it -p 8888:8888 -v $data_path:/home/dataset notebook_dl4mic
    fi
fi