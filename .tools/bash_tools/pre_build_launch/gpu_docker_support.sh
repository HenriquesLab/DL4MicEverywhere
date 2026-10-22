#!/bin/bash

# Check whether Docker itself can give containers access to the NVIDIA GPU,
# before a multi-GB GPU image is pulled or built. Source this file and call
# dl4me_docker_gpu_problem; it prints nothing when Docker can use the GPU, or
# one of these reasons:
#   desktop_linux      Docker Desktop for Linux is the active engine. It runs
#                      containers in a VM and cannot pass NVIDIA GPUs through.
#   no_nvidia_runtime  Docker Engine on native Linux without the NVIDIA
#                      Container Toolkit.
# Docker Desktop on Windows (WSL 2) passes GPUs through on its own, and macOS has
# no NVIDIA GPU support, so neither is checked here.

source "$(dirname "${BASH_SOURCE[0]}")/docker_state.sh" || return 1

dl4me_docker_gpu_problem() {
    [[ "${OSTYPE:-}" == "linux-gnu"* ]] || return 0
    if dl4me_is_wsl; then
        return 0
    fi

    if [ "$(docker context show 2>/dev/null)" = "desktop-linux" ]; then
        echo "desktop_linux"
        return 0
    fi

    # `--gpus` works when the toolkit's runtime is registered with Docker, or when
    # its prestart hook is installed (older toolkit setups).
    if docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -q '"nvidia"'; then
        return 0
    fi
    if command -v nvidia-container-runtime-hook >/dev/null 2>&1; then
        return 0
    fi
    echo "no_nvidia_runtime"
}

dl4me_explain_docker_gpu_problem() {
    local problem="$1"
    local basedir="$2"

    echo ""
    echo "------------------------------------"
    case "$problem" in
        desktop_linux)
            echo "GPU is not available: Docker Desktop for Linux is the active Docker engine."
            echo "Docker Desktop for Linux runs containers inside a virtual machine and cannot"
            echo "give them access to NVIDIA GPUs. Use Docker Engine instead. If it is already"
            echo "installed on this computer, switch to it with:"
            echo ""
            echo "  docker context use default"
            echo ""
            echo "Otherwise see docs/TROUBLESHOOTING.md (GPU on Linux)."
            ;;
        no_nvidia_runtime)
            echo "GPU is not available: Docker is not configured for NVIDIA GPUs on this computer."
            echo "DL4MicEverywhere does not change an existing Docker installation."
            echo ""
            /bin/bash "$basedir/.tools/bash_tools/requirements_installation/nvidia_container_toolkit.sh" --print-instructions
            ;;
    esac
    echo ""
    echo "The notebook will run on the CPU instead."
    echo "------------------------------------"
    echo ""
}
