ARG BASE_IMAGE=tensorflow/tensorflow:2.8.0-gpu
FROM ${BASE_IMAGE}

RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub \
    && rm /bin/sh && ln -s /bin/bash /bin/sh \
    && apt-get update \
    && apt-get install -y wget

WORKDIR /home 

ARG CACHEBUST=1
ARG NOTEBOOK_NAME="notebook_name"
ARG PATH_TO_NOTEBOOK="path_to_the_notebook"
ARG PATH_TO_REQUIREMENTS="path_to_the_requirements"
ARG SECTIONS_TO_REMOVE=""

# Download the selected notebook from ZeroCostDL4Mic and the requirements.txt
# RUN wget "${PATH_TO_NOTEBOOK}?raw=true" -O ${NOTEBOOK_NAME} \
#     && wget "${PATH_TO_REQUIREMENTS}?raw=true" -O requirements.txt
# Until the requirements are tested and published in a public repository, they will be stored here
RUN wget "${PATH_TO_NOTEBOOK}?raw=true" -O ${NOTEBOOK_NAME}

COPY requirements.txt .

RUN pip install -r requirements.txt \
    && rm requirements.txt

RUN wget https://github.com/IvanHCenalmor/colab_to_docker/archive/refs/heads/main.zip -O colab_to_docker.zip \
    && unzip colab_to_docker.zip \
    && rm colab_to_docker.zip \
    && pip install nbformat
RUN python colab_to_docker-main/src/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}\
    && mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} \
    && rm -r colab_to_docker-main

RUN pip install jupyterlab

CMD jupyter-lab ${NOTEBOOK_NAME} --ip='0.0.0.0' --port=8888 --no-browser --allow-root
