#!/bin/bash
BASEDIR=$(dirname "$0")

# As there are not key-value lists on bash versions lower to 4 and mac computers cannot have that version, 
# this is a way to create this key-value list
notebook_care2d="CARE_2D"
notebook_care3d="CARE_3D"
notebook_cyclegan="CycleGAN"
notebook_deepstorm2d="Deep-STORM_2D"
notebook_noise2void2d="Noise2Void_2D"
notebook_noise2void3d="Noise2Void_3D"
notebook_stardist2d="StarDist_2D"
notebook_stardist3d="StarDist_3D"
notebook_unet2d="U-Net_2D"
notebook_unet3d="U-Net_3D"
notebook_unet2dmultilabel="U-Net_2D_Multilabel"
notebook_yolov2="YOLOv2"
notebook_fnet2d="fnet_2D"
notebook_fnet3d="fnet_3D"
notebook_pix2pix="pix2pix"

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] -n notebook_name -d dataset_path

Script description here.

Available options:

-h, --help      Print this help and exit
-n, --name      Name of the notebook:  - care2d
                                       - care3d
                                       - cyclegan
                                       - deepstorm2d
                                       - noise2void2d
                                       - noise2void3d
                                       - stardist2d
                                       - stardist3d
                                       - unet2d
                                       - unet3d
                                       - unet2dmultilabel
                                       - yolov2
                                       - fnet2d
                                       - fnet3d
                                       - pix2pix
-d --data_path  Path to the data directory
-g --gpu        Flag to specify if GPU should be used
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

while getopts :hn:d:g: flag;do
   case $flag in 
      h)
        usage ;;
      n)
        name="$OPTARG" ;;
      d)
        data_path="$OPTARG" ;;
      g)
        gpu_flag="$OPTARG" ;;
      \?)
        echo "Invalid option: -$OPTARG"
        echo "Try bash ./test.sh -h for more information."
        exit ;;
   esac
done

if [ -z "$name" ]; then 
   echo "No notebook name has been specified, please make sure to use -n --name argument and give a value to it."
   exit
else
   echo "Notebook name: $name"
   notebook_name=notebook_$name
   echo ${!notebook_name}
   if [ -z "${!notebook_name}" ]; then
      echo "No such name for the notebook" 
      exit
   else
      echo "Actual notebook: ${!notebook_name}" 
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
eval $(parse_yaml $BASEDIR/notebooks/${!notebook_name}_DL4Mic/configuration.yaml)

if [ $gpu_flag -eq 1 ]; then
   base_img="nvidia/cuda:${cuda_version}-base-ubuntu${ubuntu_version}"
else
   base_img="ubuntu:${ubuntu_version}"
fi

# Build and launch the docker
docker build $BASEDIR --no-cache -t "${name}_dl4mic" \
       --build-arg BASE_IMAGE="${base_img}" \
       --build-arg PYTHON_VERSIOM="${python_version}" \
       --build-arg NOTEBOOK_NAME="${!notebook_name}_DL4Mic.ipynb" \
       --build-arg PATH_TO_NOTEBOOK="${notebook_url}" \
       --build-arg PATH_TO_REQUIREMENTS="${requirements_url}" \
       --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}"

if [ $gpu_flag -eq 1 ]; then
   docker run -it --gpus all -p 8888:8888 -v $data_path:/home/dataset ${name}_dl4mic
else
   docker run -it -p 8888:8888 -v $data_path:/home/dataset ${name}_dl4mic
fi