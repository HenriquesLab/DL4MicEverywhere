#!/bin/bash

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
    
    # Install the latest Docker version. Package metadata was refreshed just
    # above after adding Docker's repository, so another update is unnecessary.
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
    # The package lists are already current from the Docker repository setup.
    sudo apt-get -y install /tmp/DockerDesktop.deb

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
    # macOS: install the current Docker Desktop release from Docker's stable,
    # architecture-specific download URLs. These unversioned URLs are the same
    # targets exposed by Docker's official macOS installation documentation.
    # Do not auto-accept the Docker Subscription Service Agreement; Docker
    # Desktop will present it to the user on first launch.
    machine_arch=$(uname -m)
    case "$machine_arch" in
        arm64)
            docker_dmg_url="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
            ;;
        x86_64)
            docker_dmg_url="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
            ;;
        *)
            echo "ERROR: Unsupported Mac architecture: $machine_arch" >&2
            exit 1
            ;;
    esac

    docker_app="${DL4ME_DOCKER_APP_PATH:-/Applications/Docker.app}"
    temp_root=$(mktemp -d "${TMPDIR:-/tmp}/dl4me-docker.XXXXXX") || exit 1
    docker_dmg="$temp_root/Docker.dmg"
    mount_point="$temp_root/mount"
    mkdir -p "$mount_point"
    docker_mounted=0

    cleanup_macos_docker_install() {
        if [ "$docker_mounted" -eq 1 ]; then
            hdiutil detach "$mount_point" -quiet >/dev/null 2>&1 || true
        fi
        rm -rf "$temp_root"
    }
    trap cleanup_macos_docker_install EXIT INT TERM

    echo "Downloading the current Docker Desktop installer for $machine_arch..."
    if ! curl -fL --retry 3 --connect-timeout 15 --max-time 1800 \
        "$docker_dmg_url" -o "$docker_dmg"; then
        echo "ERROR: Docker Desktop download failed." >&2
        exit 1
    fi

    if ! hdiutil verify "$docker_dmg" >/dev/null; then
        echo "ERROR: The downloaded Docker Desktop disk image did not pass macOS verification." >&2
        exit 1
    fi

    if ! hdiutil attach "$docker_dmg" -nobrowse -readonly -mountpoint "$mount_point" >/dev/null; then
        echo "ERROR: Docker Desktop disk image could not be mounted." >&2
        exit 1
    fi
    docker_mounted=1

    docker_installer="$mount_point/Docker.app/Contents/MacOS/install"
    if [ ! -x "$docker_installer" ]; then
        echo "ERROR: Docker Desktop installer was not found inside the mounted disk image." >&2
        exit 1
    fi

    echo "Installing Docker Desktop into /Applications..."
    echo "macOS may ask for an administrator password for this installation step."
    if ! sudo "$docker_installer" --user="$USER"; then
        echo "ERROR: Docker Desktop installer returned a failure." >&2
        exit 1
    fi

    # The official installer targets /Applications/Docker.app. Tests may
    # override the expected path without changing production behavior.
    if [ ! -d "$docker_app" ]; then
        echo "ERROR: Docker Desktop installation completed but $docker_app was not found." >&2
        exit 1
    fi

    echo "Docker Desktop was installed successfully."
    echo "On first launch, Docker Desktop will ask you to review and accept its terms."

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