#!/bin/bash

# Check if hombrew is installed on your MacOs and otherwise install it
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then

        echo "Installing Homebrew..."
    
        # Export non interactive variable to avoid asking for input
        exportNONINTERACTIVE=1 

        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >>  ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"

        if ! command -v brew &> /dev/null; then
            echo ""
            echo "------------------------------------"
            echo -e "\033[0;31 Homebrew installation failed. \033[0m"
            echo "Please try again or follow the requirements installation we provide:"
            echo "https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/REQUIREMENTS_INSTALLATION.md"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        fi
    else
        echo "Homebrew already installed."
    fi
fi

# Verify if tcl/tk is installed on the system and otherwise install it
if ! command -v wish &> /dev/null; then
    
    echo "Installing TCL/TK..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get -y update
        sudo apt -y update
        sudo apt -y upgrade
        sudo apt-get -y install tcl
        sudo apt-get -y install tk

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        brew uninstall tcl-tk
        brew install tcl-tk

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

    if ! command -v wish &> /dev/null; then
        echo ""
        echo "------------------------------------"
        echo -e "\033[0;31 Wish (TCL/TK) installation failed. \033[0m"
        echo "Please try again or follow the requirements installation we provide:"
        echo "https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/REQUIREMENTS_INSTALLATION.md"
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
else
    echo "TCL/TK already installed."
fi 

# Verify if xdg-open is installed on the system and otherwise install it
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v xdg-open &> /dev/null; then 
        echo "Installing xdg-utils..."

        sudo apt-get -y update
        sudo apt -y update
        sudo apt -y upgrade
        sudo apt-get -y install xdg-utils
        if ! command -v xdg-open &> /dev/null; then 
            echo -e "\033[0;31 xdg-utils installation failed. \033[0m"
            echo "Please try again or follow the installation instructions on: https://installati.one/install-xdg-utils-ubuntu-20-04/"
        fi
    else
        echo "xdg-utils already installed."
    fi
fi

# Verify if netstat is installed on the WSL and otherwise install it
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
        # Linux inside the Windows Subsystem for Linux needs to export/link the start command
        if ! command -v netstat &> /dev/null; then 
            echo "Installing net-tools..."

            sudo apt-get -y update
            sudo apt -y update
            sudo apt -y upgrade
            sudo apt -y install net-tools
            if ! command -v netstat &> /dev/null; then 
                echo ""
                echo "------------------------------------"
                echo -e "\033[0;31 net-tools installation failed. \033[0m"
                echo "Please try again or follow the installation instructions on:"
                echo "https://installati.one/install-net-tools-ubuntu-20-04/"
                read -p "Press enter to close the terminal."
                echo "------------------------------------" 
                exit 1
            fi
        else
            echo "net-tools already installed."
        fi
    fi
fi

# Verify if Docker is installed on the system and otherwise install it
if ! command -v docker &> /dev/null; then
    
    echo "Installing Docker..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        
        # Install the latest Docker version
        sudo apt-get -y update
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Download the Docker Desktop .deb file v4.27.1 and install it
        curl https://desktop.docker.com/linux/main/amd64/136059/docker-desktop-4.27.1-amd64.deb -o /tmp/DockerDesktop.deb
        sudo apt-get -y update
        sudo apt-get -y install /tmp/DockerDesktop.deb

        if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
            # Linux inside the Windows Subsystem for Linux needs to export/link the start command
            "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe"
            pid_docker=$!
            # Wait until is opened
            wait $pid_docker
            while ! docker info &> /dev/null; do
                sleep 5
            done
        else
            # Native Linux
            systemctl --user start docker-desktop
            pid_docker=$!
            # Wait until is opened
            wait $pid_docker
            while ! docker info &> /dev/null; do
                sleep 5
            done
        fi

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

        # Launch Docker Desktop
        open -a Docker &
        pid_docker=$!
        # Wait until is opened
        wait $pid_docker
        while ! docker info &> /dev/null; do
            sleep 5
        done

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
    
    if ! command -v docker &> /dev/null; then
        echo ""
        echo "------------------------------------"
        echo -e "\033[0;31 Docker installation failed. \033[0m"
        echo "Please try again or follow the installation instructions on:"
        echo "https://installati.one/install-net-tools-ubuntu-20-04/"
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
else
    echo "Docker already installed."
fi