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

# Set timezone for Python installation
ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Instal Python 
ARG PYTHON_VERSIOM="9"
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python${PYTHON_VERSIOM} python${PYTHON_VERSIOM}-dev python3-pip python${PYTHON_VERSIOM}-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python${PYTHON_VERSIOM} -m pip install pip --upgrade && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSIOM} 0 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSIOM} 0

# Run nvidia-cudnn-cu11 for Python
RUN pip install nvidia-cudnn-cu11==8.6.0.163
# And export the environment variable LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH lib/:/usr/local/lib/python${PYTHON_VERSIOM}/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH

WORKDIR /home 

# Read all the arguments to load the nteobook and requirements
ARG NOTEBOOK_NAME="notebook_name"
ARG PATH_TO_NOTEBOOK="path_to_the_notebook"
ARG PATH_TO_REQUIREMENTS="path_to_the_requirements"
ARG SECTIONS_TO_REMOVE=""

# Download the notebook and requirements
RUN wget "${PATH_TO_NOTEBOOK}?raw=true" -O ${NOTEBOOK_NAME} && \
    wget "${PATH_TO_REQUIREMENTS}?raw=true" -O requirements.txt

# Install the requirements 
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    rm requirements.txt

# Transfrom the ZCDL4Mic colab notebook to a 'colabless' version
RUN wget https://github.com/IvanHCenalmor/colab_to_docker/archive/refs/heads/main.zip -O colab_to_docker.zip \
    && unzip colab_to_docker.zip \
    && rm colab_to_docker.zip \
    && pip install nbformat

RUN python colab_to_docker-main/src/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}\
    && mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} \
    && rm -r colab_to_docker-main

# Install jupyterlab and ipywidgets
RUN pip install jupyterlab ipywidgets

# Run the notebook
CMD jupyter-lab ${NOTEBOOK_NAME} --ip='0.0.0.0' --port=8888 --no-browser --allow-root