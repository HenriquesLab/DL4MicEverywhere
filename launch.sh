#!/bin/bash

echo $BASH_VERSION

declare -A notebook_dict
notebook_dict[care2d]="CARE_2D_DL4Mic"
notebook_dict[care3d]="CARE_3D_DL4Mic"
notebook_dict[cyclegan]=CycleGAN_DL4Mic
notebook_dict[deepstorm2d]=Deep-STORM_2D_DL4Mic
notebook_dict[noise2void2d]=Noise2Void_2D_DL4Mic
notebook_dict[noise2void3d]=Noise2Void_3D_DL4Mic
notebook_dict[stardist2d]=StarDist_2D_DL4Mic
notebook_dict[stardist3d]=StarDist_3D_DL4Mic
notebook_dict[unet2d]="U-Net_2D_DL4Mic"
notebook_dict[unet3d]="U-Net_3D_DL4Mic"
notebook_dict[unet2dmultilabel]=U-Net_2D_Multilabel_DL4Mic
notebook_dict[yolov2]=YOLOv2_DL4Mic
notebook_dict[fnet2d]=fnet_2D_DL4Mic
notebook_dict[fnet3d]=fnet_3D_DL4Mic
notebook_dict[pix2pix]=pix2pix_DL4Mic


usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] -v version -n notebook_name

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --version   Version of the notebook
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

EOF
  exit
}

while getopts :hv:n:d: flag;do
   case $flag in 
      h)
        usage ;;
      v)
        version="$OPTARG" ;;
      n)
        name="$OPTARG" ;;
      d)
        data_path="$OPTARG" ;;
      \?)
        echo "Invalid option: -$OPTARG"
        echo "Try bash ./test.sh -h for more information."
        exit ;;
   esac
done

if [ -z "$version" ]; then 
   echo "No version has been specified, please make sure to use -v --version argument and give a value to it."
   exit
else
   echo "version $version"
fi 

if [ -z "$name" ]; then 
   echo "No notebook name has been specified, please make sure to use -n --name argument and give a value to it."
   exit
else
   echo "name $name"
   if [ -v "${notebook_dict[$name]}" ]; then
      echo "No such name for the notebook" 
      exit
   else
      echo "notebook ${notebook_dict[$name]}" 
   fi
fi 

if [ -z "$data_path" ]; then 
   echo "No data path has been specified, please make sure to use -d --data_path argument and give a value to it."
   exit
else
   echo "data_path $data_path"
fi 

bash "/notebooks/${notebook_dict[$name]}/docker.sh" -v $version -d $data_path