#!/bin/bash
BASEDIR=$(dirname "$(readlink -f "$0")")
echo "WARNING: Docker daemon is not running."

# Launch the window asking the user to launch Docker Desktop.
docker_flag=$(wish "$BASEDIR/../../tcl_tools/docker_desktop_gui.tcl")
# docker_flag == 3 --> Yes, launch
# docker_flag == 2 --> No, do not launch

if [[ "$docker_flag" -eq 2 ]]; then
    echo ""
    echo "------------------------------------"
    echo "Docker daemon or Docker Desktop needs to be running."
    echo "Make sure that it is correctly installed."
    echo "If you want, you can start Docker Desktop by yourself."
    read -p "Press enter to close the terminal."
    echo "------------------------------------"
    exit 1
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
        # Docker Desktop can be installed either per-user (current recommended
        # Windows mode) or for all users. Discover both from inside WSL.
        docker_desktop_exe=""

        if command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
            localappdata_win=$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r' | tail -n 1)
            if [[ -n "$localappdata_win" && "$localappdata_win" != "%LOCALAPPDATA%" ]]; then
                localappdata_wsl=$(wslpath "$localappdata_win" 2>/dev/null || true)
                per_user_exe="$localappdata_wsl/Programs/DockerDesktop/Docker Desktop.exe"
                if [[ -f "$per_user_exe" ]]; then
                    docker_desktop_exe="$per_user_exe"
                fi
            fi
        fi

        if [[ -z "$docker_desktop_exe" && -f "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe" ]]; then
            docker_desktop_exe="/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe"
        fi

        if [[ -z "$docker_desktop_exe" ]]; then
            echo ""
            echo "------------------------------------"
            echo "Docker Desktop executable could not be found from WSL."
            echo "Run Windows_launch.bat so DL4MicEverywhere can discover or install Docker Desktop."
            echo "------------------------------------"
            exit 1
        fi

        "$docker_desktop_exe" >/dev/null 2>&1 &
    else
        systemctl --user start docker-desktop >/dev/null 2>&1 || true
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    open -a Docker >/dev/null 2>&1 &
elif [[ "$OSTYPE" == "msys"* ]]; then
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

# Wait up to two minutes for the engine to become responsive. This also covers
# a slower first launch after a fresh per-user Docker Desktop installation.
for _ in $(seq 1 60); do
    if docker info &> /dev/null; then
        exit 0
    fi
    sleep 2
done

echo ""
echo "------------------------------------"
echo "Docker daemon or Docker Desktop has still not been started."
echo "Make sure that it is correctly installed and running."
echo "If you want, you can start Docker Desktop by yourself."
echo "Run DL4MicEverywhere again when it is running."
read -p "Press enter to close the terminal."
echo "------------------------------------"
exit 1
