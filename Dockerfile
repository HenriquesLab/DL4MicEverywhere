ARG BASE_IMAGE="nvidia/cuda:11.8.0-base-ubuntu22.04"
FROM ${BASE_IMAGE}

# Install common packages and nvidia-cuda-toolkit
RUN apt-get update && \
    apt-get install -y build-essential \
                       software-properties-common \
                       curl \
                       wget \ 
                       unzip \
                       git \
                       nvidia-cuda-toolkit && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instal Python 
ARG PYTHON_VERSIOM="9"
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.${PYTHON_VERSIOM} python3.${PYTHON_VERSIOM}-dev python3-pip python3.${PYTHON_VERSIOM}-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python3.${PYTHON_VERSIOM} -m pip install pip --upgrade && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.${PYTHON_VERSIOM} 0 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.${PYTHON_VERSIOM} 0

# Run nvidia-cudnn-cu11 for Python
RUN pip install nvidia-cudnn-cu11==8.6.0.163
# And export the environment variable LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH lib/:/usr/local/lib/python3.${PYTHON_VERSIOM}/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH

WORKDIR /home 

ARG NOTEBOOK_NAME="notebook_name"
ARG PATH_TO_NOTEBOOK="path_to_the_notebook"
ARG PATH_TO_REQUIREMENTS="path_to_the_requirements"
ARG SECTIONS_TO_REMOVE=""

RUN wget "${PATH_TO_NOTEBOOK}?raw=true" -O ${NOTEBOOK_NAME} && \
    wget "${PATH_TO_REQUIREMENTS}?raw=true" -O requirements.txt

RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    rm requirements.txt

RUN wget https://github.com/IvanHCenalmor/colab_to_docker/archive/refs/heads/main.zip -O colab_to_docker.zip \
    && unzip colab_to_docker.zip \
    && rm colab_to_docker.zip \
    && pip install nbformat

RUN python colab_to_docker-main/src/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}\
    && mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} \
    && rm -r colab_to_docker-main

RUN pip install jupyterlab ipywidgets

CMD jupyter-lab ${NOTEBOOK_NAME} --ip='0.0.0.0' --port=8888 --no-browser --allow-root
ddo