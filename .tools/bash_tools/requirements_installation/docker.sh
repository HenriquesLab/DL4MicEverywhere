echo "Installing Docker..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    # Add Docker's official GPG key:
    sudo apt-get -y update
    sudo apt-get -y install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get -y update
    
    # Install the latest Docker version
    sudo apt-get -y update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    ## Allow to run Docker as a non-root user
    # Create a docker group
    sudo groupadd docker
    # Add your user to that group
    sudo usermod -aG docker $USER
    
    # As we will tell the user to restart its machine, this will not be needed
    # Activate the changes to groups
    # newgrp docker

    # Check if the OS is Ubuntu 24.04 (Docker Destop is still not supported on it)
    ubuntu_v=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -f2 -d'=')
    # Check if the actual version is 24.04
    if [[ "${ubuntu_v//\"}" == "24.04" ]]; then
        # As they say in their original installation guide: https://docs.docker.com/desktop/install/ubuntu/
        # The latest Ubuntu 24.04 LTS is not yet supported. Docker Desktop will fail to start. 
        # Due to a change in how the latest Ubuntu release restricts the unprivileged namespaces, 
        # sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 needs to be run at least once
        
        # This command would only work for the actual session, after reboot will be lost
        # sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
        
        # As previous command would be lost, we need to make it permanent modifying the following file
        echo 'kernel.apparmor_restrict_unprivileged_userns = 0' | sudo tee -a /etc/sysctl.conf
        # Instead of using "echo >>", as we need to use sudo, we will use "tee -a"
    fi

    # Install latest Docker Desktop version
    curl https://desktop.docker.com/linux/main/$(dpkg --print-architecture)/docker-desktop-$(dpkg --print-architecture).deb -o /tmp/DockerDesktop.deb
    sudo apt-get -y update
    sudo apt-get -y install /tmp/DockerDesktop.deb

    # Download the Docker Desktop .deb file v4.27.1 and install it
    # curl https://desktop.docker.com/linux/main/amd64/136059/docker-desktop-4.27.1-amd64.deb -o /tmp/DockerDesktop.deb
    # sudo apt-get -y update
    # sudo apt-get -y install /tmp/DockerDesktop.deb

    # We want the user to restart its machine, for that reason we will not launch Docker Desktop

    # if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
    #     # Linux inside the Windows Subsystem for Linux needs to export/link the start command
    #     "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe"
    #     pid_docker=$!
    #     # Wait until is opened
    #     wait $pid_docker
    #     while ! docker info &> /dev/null; do
    #         sleep 5
    #     done
    # else
    #     # Native Linux
    #     systemctl --user start docker-desktop
    #     pid_docker=$!
    #     # Wait until is opened
    #     wait $pid_docker
    #     while ! docker info &> /dev/null; do
    #         sleep 5
    #     done
    # fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX

    # Install podman
    # brew install podman
    # podman machine init
    # podman machine start

    # # Check if is an Apple Silicon chip
    if [[ $(uname -m) == 'arm64' ]]; then
        # Docker official website, to get the best experience, still recommends to install Rosetta
        # To install Rosetta 2 manually from the command line, run the following command:
        softwareupdate --agree-to-license --install-rosetta

        # Download the v4.27.1 ARM64 Docker installer
        curl https://desktop.docker.com/mac/main/arm64/136059/Docker.dmg -o /tmp/Docker.dmg
    else
        # Download the v4.27.1 latest AMD64 Docker installer
        curl https://desktop.docker.com/mac/main/amd64/136059/Docker.dmg -o /tmp/Docker.dmg
    fi

    # Install Docker Desktop
    hdiutil attach /tmp/Docker.dmg
    /Volumes/Docker/Docker.app/Contents/MacOS/install
    hdiutil detach /Volumes/Docker

    # Add Docker Desktop (docker) to the environment variable PATH
    echo 'export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"' >> ~/.zshrc
    echo 'export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"' >> ~/.bashrc

    # We want the user to restart its machine, for that reason we will not launch Docker Desktop

    # # Launch Docker Desktop
    # open -a Docker &
    # pid_docker=$!
    # # Wait until is opened
    # wait $pid_docker
    # while ! docker info &> /dev/null; do
    #     sleep 5
    # done

elif [[ "$OSTYPE" == "msys*" ]]; then
    # Windows
    echo "This is a Windows machine"
else
    echo ""
    echo "------------------------------------"
    echo "Unsupported OS: $OSTYPE"
    echo "We only provide support for Windows, MacOS and Linux."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
fi