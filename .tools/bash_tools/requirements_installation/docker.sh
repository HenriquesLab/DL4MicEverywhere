#!/bin/bash

echo "Installing Docker..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: install Docker Engine only. Docker Desktop for Linux runs containers
    # inside a VM that cannot pass NVIDIA GPUs through (`--gpus` is only supported
    # by Docker Desktop on Windows/WSL2), so it is not installed on native Linux.

    # Inside WSL, Docker is provided by Docker Desktop for Windows through its WSL
    # integration. Installing Docker Engine in the distribution would shadow that
    # integration, so never do it here.
    if command -v systemd-detect-virt >/dev/null 2>&1 && [[ "$(systemd-detect-virt 2>/dev/null)" == "wsl"* ]]; then
        echo ""
        echo "------------------------------------"
        echo "The docker command is not available inside this WSL distribution."
        echo "DL4MicEverywhere uses Docker Desktop for Windows with WSL integration and does"
        echo "not install Docker Engine inside WSL. Run Windows_launch.bat so it can check"
        echo "Docker Desktop and its WSL integration for this Ubuntu distribution."
        echo "------------------------------------"
        exit 1
    fi

    # Docker's packages conflict with distribution packages such as docker.io,
    # containerd, runc and podman-docker; apt would silently remove them. Such
    # hosts (for example CI or Kubernetes nodes) are managed by someone else, so
    # stop and explain instead of changing them.
    conflicting_packages=""
    for package in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            conflicting_packages="$conflicting_packages $package"
        fi
    done
    if [ -n "$conflicting_packages" ]; then
        echo ""
        echo "------------------------------------"
        echo "Docker Engine was not installed because these packages are already present:"
        echo " $conflicting_packages"
        echo "Installing Docker's official packages would remove them, which could disrupt"
        echo "other software on this computer. DL4MicEverywhere does not change existing"
        echo "container installations."
        echo ""
        echo "If this computer is managed by someone else, ask them to make the docker"
        echo "command available to your user. Otherwise follow Docker's guide:"
        echo "  https://docs.docker.com/engine/install/ubuntu/"
        echo "------------------------------------"
        exit 1
    fi

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
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || exit 1

    # Start Docker now and on every boot, so there is no separate "start Docker"
    # step for the user (unlike Docker Desktop).
    sudo systemctl enable --now docker || exit 1

    ## Allow to run Docker as a non-root user
    # The docker-ce package normally creates the docker group already.
    getent group docker >/dev/null || sudo groupadd docker
    # Add your user to that group. This takes effect after logging out and back in.
    sudo usermod -aG docker "$USER" || exit 1

    # Tell the caller that Docker Engine was installed in this run. Only a freshly
    # installed Engine may be configured for NVIDIA GPUs automatically, because
    # that requires restarting the Docker daemon.
    if [ -n "${DL4ME_DOCKER_INSTALLED_MARKER:-}" ]; then
        : > "$DL4ME_DOCKER_INSTALLED_MARKER"
    fi

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