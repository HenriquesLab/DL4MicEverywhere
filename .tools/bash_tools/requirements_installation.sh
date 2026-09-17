#!/bin/bash

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1
source "$BASEDIR/macos_env.sh" || exit 1

any_installation_flag=0

show_install_failure() {
    local component="$1"
    local guidance="$2"
    echo ""
    echo "------------------------------------"
    echo "$component installation failed."
    if [ -n "$guidance" ]; then
        echo "$guidance"
    fi
    echo "Please review the message above and try again."
    echo "------------------------------------"
    if [ "${DL4ME_WINDOWS_WRAPPER:-0}" != "1" ] && [ "${DL4ME_MACOS_WRAPPER:-0}" != "1" ] && [ -t 0 ]; then
        read -r -p "Press enter to close the terminal."
    fi
    return 1
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    dl4me_setup_macos_path

    # Homebrew is used only for lightweight host dependencies such as Tcl/Tk
    # and Python lock-generation tooling. Support both Apple Silicon and Intel
    # default prefixes without evaluating shell code or requiring profile edits.
    if ! command -v brew >/dev/null 2>&1; then
        /bin/bash "$BASEDIR/requirements_installation/homebrew.sh" || {
            show_install_failure "Homebrew" "See https://brew.sh for Homebrew's supported installation instructions."
            exit 1
        }
        dl4me_setup_macos_path
        if ! command -v brew >/dev/null 2>&1; then
            show_install_failure "Homebrew" "The installer completed, but brew is still not available to DL4MicEverywhere."
            exit 1
        fi
        any_installation_flag=1
    else
        echo "Homebrew already installed."
    fi
fi

# Verify Tcl/Tk (wish), installing it when needed.
if ! command -v wish >/dev/null 2>&1; then
    /bin/bash "$BASEDIR/requirements_installation/tcl_tk.sh" || {
        show_install_failure "Tcl/Tk" "DL4MicEverywhere requires the wish GUI executable."
        exit 1
    }
    if [[ "$OSTYPE" == "darwin"* ]]; then
        dl4me_setup_macos_path
    fi
    if ! command -v wish >/dev/null 2>&1; then
        show_install_failure "Tcl/Tk" "Tcl/Tk was installed, but wish could not be located."
        exit 1
    fi
    any_installation_flag=1
else
    echo "Tcl/Tk already installed."
fi

# Create/read preferences only after wish is known to be available.
if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    /bin/bash "$BASEDIR/../bash_tools/cache_preferences.sh"
fi

# Linux browser integration.
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v xdg-open >/dev/null 2>&1; then
        /bin/bash "$BASEDIR/requirements_installation/xdg_utils.sh" || exit 1
        if ! command -v xdg-open >/dev/null 2>&1; then
            show_install_failure "xdg-utils" "The xdg-open browser helper is required on native Linux."
            exit 1
        fi
        any_installation_flag=1
    else
        echo "xdg-utils already installed."
    fi
fi

# Legacy WSL helper requirement. The Windows wrapper normally supplies the
# modern WSL path, but keep direct WSL launches compatible.
if [[ "$OSTYPE" == "linux-gnu"* ]] && command -v systemd-detect-virt >/dev/null 2>&1; then
    if [[ "$(systemd-detect-virt 2>/dev/null)" == "wsl"* ]]; then
        if ! command -v netstat >/dev/null 2>&1; then
            /bin/bash "$BASEDIR/requirements_installation/net_tools.sh" || exit 1
            if ! command -v netstat >/dev/null 2>&1; then
                show_install_failure "net-tools" "netstat could not be installed inside WSL."
                exit 1
            fi
            any_installation_flag=1
        else
            echo "net-tools already installed."
        fi
    fi
fi

if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    containerisation="Docker"
else
    containerisation=$(awk -F' : ' '$1 == "containerisation" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
fi

if [[ "$containerisation" == "Docker"* ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        docker_app="${DL4ME_DOCKER_APP_PATH:-/Applications/Docker.app}"

        # A standalone docker CLI is not sufficient on macOS; DL4MicEverywhere
        # needs the Docker Desktop engine/application as well.
        if [ ! -d "$docker_app" ]; then
            /bin/bash "$BASEDIR/requirements_installation/docker.sh" || {
                show_install_failure "Docker Desktop" "The current Docker Desktop installer could not be completed."
                exit 1
            }
            any_installation_flag=1
        else
            echo "Docker Desktop already installed."
        fi

        dl4me_setup_macos_path
        if [ ! -d "$docker_app" ] || ! command -v docker >/dev/null 2>&1; then
            show_install_failure "Docker Desktop" "Docker.app or its Docker CLI could not be located after installation."
            exit 1
        fi
    else
        if ! command -v docker >/dev/null 2>&1; then
            /bin/bash "$BASEDIR/requirements_installation/docker.sh" || exit 1
            if ! command -v docker >/dev/null 2>&1; then
                show_install_failure "Docker" "The Docker CLI could not be located after installation."
                exit 1
            fi
            any_installation_flag=1
        else
            echo "Docker already installed."
        fi
    fi

elif [[ "$containerisation" == "Singularity"* ]]; then
    if ! command -v singularity >/dev/null 2>&1; then
        /bin/bash "$BASEDIR/requirements_installation/singularity.sh" || exit 1
        if ! command -v singularity >/dev/null 2>&1; then
            show_install_failure "Singularity" "Automatic Singularity setup is not available for this host."
            exit 1
        fi
        any_installation_flag=1
    else
        echo "Singularity already installed."
    fi
else
    echo ""
    echo "------------------------------------"
    echo "The selected containerisation system could not be recognized."
    echo "------------------------------------"
    exit 1
fi

# Homebrew, Tcl/Tk, and Docker Desktop installations on macOS do not require a
# whole-machine reboot. Refreshing this launcher's PATH is sufficient; Docker
# Desktop readiness is handled immediately afterward by pre_launch_test.sh.
if [[ "$any_installation_flag" -ne 0 && "$OSTYPE" == "darwin"* ]]; then
    dl4me_setup_macos_path
    echo ""
    echo "------------------------------------"
    echo "macOS prerequisites were installed successfully."
    echo "No system restart is required; DL4MicEverywhere will continue setup now."
    echo "------------------------------------"
    exit 0
fi

# Linux/WSL installations may change groups or system services, so preserve the
# existing restart workflow there.
if [[ "$any_installation_flag" -ne 0 ]]; then
    echo ""
    echo "------------------------------------"
    echo "All dependencies have been successfully installed!"
    echo "It's recommended to restart your computer to apply all changes."
    echo "------------------------------------"

    requirements_flag=$(wish "$BASEDIR/../tcl_tools/restart_computer.tcl")

    if [[ "$requirements_flag" == "restart_now" ]]; then
        if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
            if command -v shutdown.exe >/dev/null 2>&1; then
                echo "Restarting Windows now..."
                if shutdown.exe /r /t 0 /c "DL4MicEverywhere installation completed. Restarting to apply changes." >/dev/null 2>&1; then
                    exit 91
                fi
            fi

            echo ""
            echo "------------------------------------"
            echo "Could not schedule the Windows restart automatically."
            echo "Please restart Windows manually before running DL4MicEverywhere again."
            echo "------------------------------------"
            exit 90
        fi

        if sudo shutdown -r now; then
            exit 91
        fi

        echo "Automatic restart failed. Please restart your computer manually."
        exit 90

    elif [[ "$requirements_flag" == "restart_later" ]]; then
        echo "Restart postponed. Please restart your computer before running DL4MicEverywhere again."
        exit 90
    else
        echo "Restart dialog closed. Please restart your computer before running DL4MicEverywhere again."
        exit 90
    fi
fi

exit 0
