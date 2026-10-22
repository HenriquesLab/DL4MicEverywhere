#!/bin/bash

# Configure Docker Engine for NVIDIA GPUs with the NVIDIA Container Toolkit.
# Usage:
#   nvidia_container_toolkit.sh                       Install and configure it.
#   nvidia_container_toolkit.sh --print-instructions  Only print the commands.
#
# The toolkit does not depend on the NVIDIA driver version: it mounts the host's
# own driver libraries into containers at run time. It never installs or changes
# the NVIDIA driver itself.
#
# Configuring it rewrites /etc/docker/daemon.json and restarts the Docker daemon,
# which stops every running container. requirements_installation.sh therefore
# only runs the installation right after DL4MicEverywhere installed Docker
# Engine itself. On an existing Docker installation only the instructions are
# shown, so the machine's administrator can decide when to apply them.

print_instructions() {
    cat <<'EOF'
To let Docker use your NVIDIA GPU, install the NVIDIA Container Toolkit
(https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html):

  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker

WARNING: restarting Docker stops every running container on this computer.
EOF
}

if [ "${1:-}" = "--print-instructions" ]; then
    print_instructions
    exit 0
fi

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    exit 0
fi

echo "Installing the NVIDIA Container Toolkit so Docker can use the NVIDIA GPU..."
echo "This adds NVIDIA's official apt repository (nvidia.github.io/libnvidia-container)."

keyring=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

if ! command -v gpg >/dev/null 2>&1; then
    sudo apt-get install -y gnupg || exit 1
fi

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --batch --yes --dearmor -o "$keyring" || exit 1
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed "s#deb https://#deb [signed-by=$keyring] https://#g" \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null || exit 1

sudo apt-get update || exit 1
sudo apt-get install -y nvidia-container-toolkit || exit 1
sudo nvidia-ctk runtime configure --runtime=docker || exit 1
sudo systemctl restart docker || exit 1

if ! sudo docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -q '"nvidia"'; then
    echo "The NVIDIA Container Toolkit was installed, but Docker does not list the nvidia runtime." >&2
    exit 1
fi

echo "NVIDIA Container Toolkit installed and Docker configured."
