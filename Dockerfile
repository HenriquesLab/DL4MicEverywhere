ARG BASE_IMAGE=""
FROM ${BASE_IMAGE}

ARG GPU_FLAG=""

# Install common packages and nvidia-cuda-toolkit
RUN apt-get update && \
    apt-get install -y build-essential \
                       software-properties-common \
                       curl \
                       wget \ 
                       unzip \
                       git \
                       libfreetype6-dev \
                       ffmpeg \
                       libsm6 \
                       libxext6 \
                       pkg-config && \
    if [ "$GPU_FLAG" -eq "1" ] ; then apt-get install -y nvidia-cuda-toolkit ; fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set timezone for Python installation
ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Instal Python 
ARG PYTHON_VERSION=""
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python3-pip python${PYTHON_VERSION}-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python${PYTHON_VERSION} -m pip install pip --upgrade && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 0 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 0

# Run nvidia-cudnn-cu11 for Python
RUN if [ "$GPU_FLAG" -eq "1" ] ; then pip install nvidia-cudnn-cu11==8.6.0.163 ; fi
# And export the environment variable LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH lib/:/usr/local/lib/python${PYTHON_VERSION}/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH

WORKDIR /home 

# Read all the arguments to load the nteobook and requirements
ARG PATH_TO_NOTEBOOK=""
ARG PATH_TO_REQUIREMENTS=""
ARG SECTIONS_TO_REMOVE=""
ARG NOTEBOOK_NAME=""

# Download the notebook and requirements if they are not provided
ADD $PATH_TO_NOTEBOOK ./${NOTEBOOK_NAME}
ADD $PATH_TO_REQUIREMENTS ./requirements.txt

# Install the requirements 
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    rm requirements.txt

# Transfrom the ZCDL4Mic colab notebook to a 'colabless' version
RUN git clone https://github.com/IvanHCenalmor/colab_to_docker.git && \
    pip install nbformat
RUN python colab_to_docker/src/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}\
    && mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} \
    && rm -r colab_to_docker

# Install jupyterlab and ipywidgets
RUN pip install jupyterlab ipywidgets

# Run the notebook
CMD jupyter-lab "$NOTEBOOK_NAME" --ip='0.0.0.0' --port=8888 --no-browser --allow-root