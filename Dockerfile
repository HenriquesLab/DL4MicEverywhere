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
    pkg-config \
    nodejs && \
    if [ "$GPU_FLAG" -eq "1" ] ; then apt-get install -y nvidia-cuda-toolkit ; fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set timezone for Python installation
ENV TZ=Europe/Lisbon
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/download/23.3.1-1/Mambaforge-23.3.1-1-Linux-x86_64.sh -O ~/conda.sh
RUN /bin/bash ~/conda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH

WORKDIR /home 
ADD . DL4MicEverywhere

# Read all the arguments to load the notebook and requirements
# Read all the arguments to load the notebook and requirements
ARG PATH_TO_NOTEBOOK=""
ARG PATH_TO_REQUIREMENTS=""
ARG SECTIONS_TO_REMOVE=""
ARG NOTEBOOK_NAME=""

# Download the notebook and requirements if they are not provided
# ADD $PATH_TO_NOTEBOOK ./${NOTEBOOK_NAME}
# ADD $PATH_TO_REQUIREMENTS ./requirements.txt

ARG PYTHON_VERSION=""
RUN conda create -y --name aux_env python=${PYTHON_VERSION} mamba

RUN /bin/bash -c "source activate aux_env"
WORKDIR /home/DL4MicEverywhere
RUN mamba env update -f environment.yml -n aux_env
WORKDIR /home
RUN pip install requirements.txt
RUN conda clean --all -f -y
RUN python DL4MicEverywhere/.tools/notebook_autoconversion/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE} && \ 
    mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} && \ 
    rm -r DL4MicEverywhere

CMD ["conda", "run", "-n", "aux_env"]