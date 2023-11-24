ARG BASE_IMAGE=""
FROM ${BASE_IMAGE}

ARG GPU_FLAG=""

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
                       nodejs && \
    if [ "$GPU_FLAG" -eq "1" ] ; then apt-get install -y nvidia-cuda-toolkit ; fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O miniconda.sh
RUN /bin/bash miniconda.sh -b -p /opt/conda
RUN rm miniconda.sh

ENV PATH=$CONDA_DIR/bin:$PATH

WORKDIR /home 

# Read all the arguments to load the nteobook and requirements
ARG PATH_TO_NOTEBOOK=""
ARG PATH_TO_REQUIREMENTS=""
ARG SECTIONS_TO_REMOVE=""
ARG NOTEBOOK_NAME=""

# Download the notebook and requirements if they are not provided
ADD $PATH_TO_NOTEBOOK ./${NOTEBOOK_NAME}
ADD $PATH_TO_REQUIREMENTS ./requirements.txt

# Create the environment with the desired Python version
RUN conda create -n dl4miceverywhere python=3.10
# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "dl4miceverywhere", "/bin/bash", "-c"]

# RUN python -m ipykernel install --name kernel_one --display-name "Display Name One"

# Install the requirements and convert the notebook
RUN pip install -r requirements.txt

RUN rm requirements.txt
RUN git clone https://github.com/HenriquesLab/DL4MicEverywhere.git
RUN pip install nbformat jupyterlab ipywidgets
RUN python DL4MicEverywhere/.tools/notebook_autoconversion/transform.py -p . -n ${NOTEBOOK_NAME} -s ${SECTIONS_TO_REMOVE}
RUN mv colabless_${NOTEBOOK_NAME} ${NOTEBOOK_NAME}
RUN rm -r DL4MicEverywhere

ENV XLA_FLAGS=--xla_gpu_cuda_data_dir=/usr/lib/cuda

# ENV NB_USER feynman
# ENV NB_UID 1000

# RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

# WORKDIR /home/${NB_USER}
# USER $NB_USER

# SHELL ["/bin/bash","-c"]
# RUN conda init
# RUN echo 'conda activate dl4miceverywhere' >> ~/.bashrc


# ENTRYPOINT ["conda", "run", "-n", "dl4miceverywhere"]
