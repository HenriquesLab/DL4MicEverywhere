ARG BASE_IMAGE=""
FROM ${BASE_IMAGE}

# Read all the arguments to load the nteobook and requirements
ARG PATH_TO_NOTEBOOK=""
ARG PATH_TO_REQUIREMENTS=""
ARG SECTIONS_TO_REMOVE=""
ARG NOTEBOOK_NAME=""
ARG CUDA_VERSION=""
ARG GPU_FLAG=""
ARG PYTHON_VERSION=""
ARG ARCH=""

# Install base utilities
RUN apt-get update \
    && apt-get install -y build-essential \
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
                       nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /home

# Download the notebook and requirements if they are not provided
ADD $PATH_TO_NOTEBOOK ./${NOTEBOOK_NAME}
ADD $PATH_TO_REQUIREMENTS ./requirements.txt

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN if [ "$ARCH" = "arm64" ] ; \
    then wget --quiet "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh" -O miniconda.sh ; \
    else wget --quiet "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O miniconda.sh ; fi \
    && /bin/bash miniconda.sh -b -p ${CONDA_DIR} \
    && rm miniconda.sh \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Add the conda path to environment variables
ENV PATH ${CONDA_DIR}/bin:$PATH
ENV LD_LIBRARY_PATH ${CONDA_DIR}/lib:$LD_LIBRARY_PATH

# Create the environment with the desired Python version
RUN conda create -n dl4miceverywhere python=${PYTHON_VERSION}

# Activate the conda environment
RUN echo "source activate dl4miceverywhere" > ~/.bashrc
ENV PATH /opt/conda/envs/dl4miceverywhere/bin:$PATH

# Install cudatoolkit in case GPU has selected
# Clone the repository and execute the notebook conversion
RUN if [ "$GPU_FLAG" -eq "1" ] ; then conda install -y -c conda-forge cudatoolkit=${CUDA_VERSION} cudnn=8.1.0; fi

RUN pip install --no-cache-dir -r requirements.txt \
    && rm requirements.txt \
    && pip install --no-cache-dir nbformat ipywidgets \
    && git clone https://github.com/HenriquesLab/DL4MicEverywhere.git \
    && python DL4MicEverywhere/.tools/notebook_autoconversion/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE} \
    && mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME} \
    && rm -r DL4MicEverywhere

# Add the environment variable XLA_FLAGS
ENV XLA_FLAGS=--xla_gpu_cuda_data_dir=/usr/lib/cuda

# Install jupyterlab
RUN pip install jupyterlab
# Create  a entrypoint that will be executed when running the docker
ENTRYPOINT jupyter lab ${NOTEBOOK_NAME} --ip='0.0.0.0' --no-browser --allow-root