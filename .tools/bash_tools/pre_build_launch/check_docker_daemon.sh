#!/bin/bash
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/../path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1
source "$BASEDIR/../macos_env.sh" || exit 1
if [[ "${OSTYPE:-}" == "darwin"* ]]; then
    dl4me_setup_macos_path
fi
echo "WARNING: Docker daemon is not running."

# Launch the window asking the user to launch Docker Desktop.
docker_flag=$(wish "$BASEDIR/../../tcl_tools/docker_desktop_gui.tcl")
# docker_flag == 3 --> Yes, launch
# docker_flag == 2 --> No, do not launch

pause_if_unwrapped() {
    if [ "${DL4ME_WINDOWS_WRAPPER:-0}" != "1" ] && [ "${DL4ME_MACOS_WRAPPER:-0}" != "1" ] && [ -t 0 ]; then
        read -r -p "Press enter to close the terminal."
    fi
}

if [[ "$docker_flag" -eq 2 ]]; then
    echo ""
    echo "------------------------------------"
    echo "Docker Desktop needs to be running before DL4MicEverywhere can continue."
    echo "Start Docker Desktop, wait for the engine to report that it is ready, and try again."
    pause_if_unwrapped
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
    docker_app="${DL4ME_DOCKER_APP_PATH:-/Applications/Docker.app}"
    if [ ! -d "$docker_app" ]; then
        echo ""
        echo "------------------------------------"
        echo "Docker Desktop is not installed in /Applications."
        echo "Run DL4MicEverywhere again so its prerequisite installer can install Docker Desktop."
        echo "------------------------------------"
        exit 1
    fi

    echo "Starting Docker Desktop..."
    if ! open "$docker_app" >/dev/null 2>&1; then
        echo ""
        echo "------------------------------------"
        echo "macOS could not open Docker Desktop."
        echo "Open Docker Desktop manually from Applications, then run DL4MicEverywhere again."
        echo "------------------------------------"
        exit 1
    fi
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
attempt=0
while [ "$attempt" -lt 60 ]; do
    if docker info &> /dev/null; then
        exit 0
    fi
    sleep 2
    attempt=$((attempt + 1))
done

echo ""
echo "------------------------------------"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Docker Desktop opened, but the Docker engine did not become ready within two minutes."
    echo "If this is Docker Desktop's first launch, complete its license/onboarding window first."
    echo "When Docker Desktop reports that the engine is running, launch DL4MicEverywhere again."
else
    echo "Docker daemon or Docker Desktop has still not been started."
    echo "Make sure that it is correctly installed and running."
    echo "Run DL4MicEverywhere again when it is running."
fi
pause_if_unwrapped
echo "------------------------------------"
exit 1
