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
-n, --notebook_path     Path to the notebook
-r, --requirements_path Path to the requirements file
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

while getopts :hc:d:g:n:r: flag;do
   case $flag in 
      h)
        usage ;;
      c)
        config_path="$OPTARG" ;;
      d)
        data_path="$OPTARG" ;;
      g)
        gpu_flag="$OPTARG" ;;
      n)
        notebook_path="$OPTARG" ;;
      g)
        requirements_path="$OPTARG" ;;
      \?)
        echo "Invalid option: -$OPTARG"
        echo "Try bash ./test.sh -h for more information."
        exit ;;
   esac
done

if [ -z "$config_path" ]; then 
   echo "No configuration path has been specified, please make sure to use -c --config_path argument and give a value to it."
   exit
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
   exit
else
   echo "Path to the data: $data_path"
fi 

if [ -z "$gpu_flag" ]; then 
   echo "No GPU flag has been specified, therefore GPU will not be used."
   gpu_flag=0
else
   if [ $gpu_flag -eq 1 ]; then
      echo 'GPU will be allowed.'
   else
      echo 'GPU is not allowed.'
   fi
fi

# Read the variables fro mthe yaml file
eval $(parse_yaml $config_path)

if [ $gpu_flag -eq 1 ]; then
   base_img="nvidia/cuda:${cuda_version}-base-ubuntu${ubuntu_version}"
else
   base_img="ubuntu:${ubuntu_version}"
fi


if [ -z $notebook_path ]; then
   echo "Path to the notebook that will be used: $notebook_path"
else
   notebook_path=""
   echo "No notebook has been specified, therefore the notebook url specified on 'configuration.yaml' will be used."
fi

if [ -z $requirements_path ]; then
   echo "Path to the notebook that will be used: $requirements_path"
else
   requirements_path=""
   echo "No requirements file has been specified, therefore the requirements url specified on 'configuration.yaml' will be used."
fi


# Build and launch the docker
docker build $BASEDIR --no-cache -t "notebook_dl4mic" \
       --build-arg BASE_IMAGE="${base_img}" \
       --build-arg PYTHON_VERSIOM="${python_version}" \
       --build-arg URL_TO_NOTEBOOK="${notebook_url}" \
       --build-arg URL_TO_REQUIREMENTS="${requirements_url}" \
       --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
       --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
       --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}"

if [ $gpu_flag -eq 1 ]; then
   docker run -it --gpus all -p 8888:8888 -v $data_path:/home/dataset notebook_dl4mic
else
   docker run -it -p 8888:8888 -v $data_path:/home/dataset notebook_dl4mic
fi