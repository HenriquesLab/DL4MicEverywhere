
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux

    # This installation steps are based on: https://docs.sylabs.io/guides/3.0/user-guide/installation.html

    ## Install the prerequisites

    ### Install Singularity's depenencies
    sudo apt-get update && sudo apt-get install -y \
        build-essential \
        libssl-dev \
        uuid-dev \
        libgpgme11-dev \
        squashfs-tools \
        libseccomp-dev \
        pkg-config

    ### Download Go package with wget and extract it on /usr/local
    VERSION=1.11 
    OS=linux 
    ARCH=amd64
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
    rm go$VERSION.$OS-$ARCH.tar.gz

    ### Set up the environment for Go
    echo 'export GOPATH=${HOME}/go' >> ~/.bashrc
    echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc
    source ~/.bashrc

    ### As we are installing Singularity v3.0.0, we also install dep for dependency resolution
    go get -u github.com/golang/dep/cmd/dep

    ## Install Singularity
    ### Build and install using Singularity RPM (allows easy installation, upgrade and remove)
    VERSION=3.0.3
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz
    rpmbuild -tb singularity-${VERSION}.tar.gz
    sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/singularity-$VERSION-1.el7.x86_64.rpm
    rm -rf ~/rpmbuild singularity-$VERSION*.tar.gz

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX

    # brew needs to be installed, but brew's installation step is before
    # so this should not give any error 

    # Check if VirtualBox is installed and installed otherwise
    if ! command brew list virtualbox &> /dev/null; then
        brew install --cask virtualbox@beta # Regular virtualbox is 7.1 and creates conflicts with vagrant
    fi
    # Check if Vagrant is installed and installed otherwise
    if ! command brew list vagrant &> /dev/null; then
        brew install --cask vagrant
    fi
    # Check if vagrant-manager is installed and install it otherwise
    if ! command brew list vagrant-manager  &> /dev/null; then
        brew install --cask vagrant-manager
    fi

    # Store actual directory/path (later the is a changing on the directory)
    actual_path="$PWD"

    # Create a directory for the Vagrant VR
    mkdir "$HOME/vm-singularity"
    cd "$HOME/vm-singularity"

    # Bring up the Virtual Machine
    vagrant init sylabs/singularity-3.0-ubuntu-bionic64
    vagrant up
    vagrant ssh

    # Go back to initial directory/path
    cd "$actual_path"

elif [[ "$OSTYPE" == "msys*" ]]; then
    # Windows
    # TODO: Finish this installation step
    echo "Windows not implemented"
else
    echo ""
    echo "------------------------------------"
    echo "Unsupported OS: $OSTYPE"
    echo "We only provide support for Windows, MacOS and Linux."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
fi