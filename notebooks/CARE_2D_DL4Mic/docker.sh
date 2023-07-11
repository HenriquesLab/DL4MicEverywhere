#!/bin/bash

usage() {}
while getopts :hv:d: flag;do
   case $flag in 
      h)
        usage ;;
      v)
        version="$OPTARG" ;;
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

if [ -z "$data_path" ]; then 
   echo "No data path has been specified, please make sure to use -d --data_path argument and give a value to it."
   exit
else
   echo "data_path $data_path"
fi 

NOTEBOOK_NAME=CARE_2D

docker build \
       --build-arg="BASE_IMAGE=tensorflow/tensorflow:2.8.0-gpu" \
       --build-arg CACHEBUST=$(date +%s) \
       --build-arg="NOTEBOOK_NAME=${NOTEBOOK_NAME}_DL4Mic.ipynb" \
       --build-arg="PATH_TO_NOTEBOOK=https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/${NOTEBOOK_NAME}_ZeroCostDL4Mic.ipynb" \
       --build-arg="PATH_TO_REQUIREMENTS=https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/${NOTEBOOK_NAME}_DL4Mic/requirements.txt" \
       -t ${NOTEBOOK_NAME}_DL4Mic . 

docker run -it --gpus all -p 8888:8888 -v $data_path:/home/dataset ${NOTEBOOK_NAME}_DL4Mic