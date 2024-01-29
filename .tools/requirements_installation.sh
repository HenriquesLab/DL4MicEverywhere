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
    else
        echo "Homebrew already installed."
    fi
fi

# Verify if tcl/tk is installed on the system and otherwise install it
if ! command -v wish &> /dev/null; then
    
    echo "Installing TCL/TK..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        apt-get install tcl
        apt-get install tk

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        brew uninstall tcl-tk
        brew install tcl-tk

    elif [[ "$OSTYPE" == "msys*" ]]; then
        # Windows
        echo "This is a Windows machine"
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
else
    echo "TCL/TK already installed."
fi 

# Verify if Docker is installed on the system and otherwise install it
if ! command -v docker &> /dev/null; then
    
    echo "Installing Docker..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        # Add Docker's official GPG key:
        apt-get update
        apt-get install ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources:
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update

        # Install the latest Docker version
        apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
            softwareupdate --install-rosetta --agree-to-license

            # Download the latest ARM64 Docker installer
            curl https://desktop.docker.com/mac/main/arm64/Docker.dmg -o /tmp/Docker.dmg
        else
            # Download the latest AMD64 Docker installer
            curl https://desktop.docker.com/mac/main/amd64/Docker.dmg -o /tmp/Docker.dmg
        fi

        # Install Docker Desktop
        hdiutil attach /tmp/Docker.dmg
        /Volumes/Docker/Docker.app/Contents/MacOS/install
        hdiutil detach /Volumes/Docker

        # Add Docker Desktop (docker) to the environment variable PATH
        export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin"

        # Launch Docker Desktop
        launchctl start docker
        # open -a Docker

    elif [[ "$OSTYPE" == "msys*" ]]; then
        # Windows
        echo "This is a Windows machine"
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
else
    echo "Docker already installed."
fi