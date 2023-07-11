#!/bin/bash

NOTEBOOK_NAME=$1
VERSION=$2
DATA_PATH=$3
# In sections_to_remove.txt the argument SECTIONS_TO_REMOVE is defined
SECTIONS_TO_REMOVE=$(<sections_to_remove.txt)

# --build-arg="PATH_TO_REQUIREMENTS=https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/${NOTEBOOK_NAME}_DL4Mic/requirements.txt" \


docker build \
       --build-arg="BASE_IMAGE=tensorflow/tensorflow:2.8.0-gpu" \
       --build-arg CACHEBUST=$(date +%s) \
       --build-arg="NOTEBOOK_NAME=${NOTEBOOK_NAME}_DL4Mic.ipynb" \
       --build-arg="PATH_TO_NOTEBOOK=https://github.com/HenriquesLab/ZeroCostDL4Mic/blob/master/Colab_notebooks/${NOTEBOOK_NAME}_ZeroCostDL4Mic.ipynb" \
       --build-arg="PATH_TO_REQUIREMENTS=./requirements.txt" \
       --build-arg="SECTIONS_TO_REMOVE=${SECTIONS_TO_REMOVE}" \
       -t ${NOTEBOOK_NAME,,}_dl4mic .

docker run -it --gpus all -p 8888:8888 -v $DATA_PATH:/home/dataset ${NOTEBOOK_NAME,,}_dl4mic