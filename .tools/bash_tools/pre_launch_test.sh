#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")

# # This script checks for root access and Docker installation on Unix-like systems
# if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
#   # Verify if the script is run as root, which is required for Docker to function correctly
#   if [ "$EUID" -ne 0 ]; then
#     echo "Please run this script as root (by using sudo). Otherwise docker won't work properly."
#     echo "Make sure to use the -E flag to preserve the environment variables when using ssh and X11"
#     echo "E.g. sudo -E bash launch.sh"
#     exit 1
#   fi
# fi

echo ""
echo "################################"
echo "Checking requirements"
echo "################################"
echo ""

/bin/bash $BASEDIR/requirements_installation.sh || exit 1

echo ""
echo "################################"
echo ""

# Check if the Docker daemon is running
if ! docker info &> /dev/null; then
    echo "WARNING: Docker daemon is not running"

    docker_flag=$(wish $BASEDIR/../tcl_tools/docker_desktop_gui.tcl)
    if [[ "$docker_flag" -ne 1 ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
                # Linux inside the Windows Subsystem for Linux needs to export/link the start command
                "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe"
                pid_docker=$!
                # Wait until is opened
                wait $pid_docker
                sleep 10
                # while ! docker info &> /dev/null; do
                #     echo "Waiting for Docker to start..."
                #     sleep 5
                # done
                # echo "Docker started"
            else
                # Native Linux
                systemctl --user start docker-desktop
                pid_docker=$!
                # Wait until is opened
                wait $pid_docker
                sleep 10
                # while ! docker info &> /dev/null; do
                #     echo "Waiting for Docker to start..."
                #     sleep 5
                # done
                # echo "Docker started"
            fi

        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac OSX
            # Launch Docker Desktop
            open -a Docker &
            pid_docker=$!
            # Wait until is opened
            wait $pid_docker
            sleep 10
            # while ! docker info &> /dev/null; do
            #     echo "Waiting for Docker to start..."
            #     sleep 5
            # done
            # echo "Docker started"
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

        if ! docker info &> /dev/null; then
            echo ""
            echo "------------------------------------"
            echo "Docker daemon or Docker Desktop has still not been started."
            echo "Make sure that is correctly installed and running."
            echo "If you want, you can start Docker Desktop by yourself."
            echo "Run DL4MicEverywhere again when it is running."
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        fi
    else
        echo ""
        echo "------------------------------------"
        echo "Docker daemon or Docker Desktop needs to be running."
        echo "Make sure that is correctly installed." 
        echo "If you want, you can start Docker Desktop by yourself."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi