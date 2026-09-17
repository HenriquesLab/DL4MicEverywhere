#!/bin/bash

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1
flag_gui="$1"
source "$BASEDIR/launcher_status.sh"

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
echo "Checking requirements ..."
echo "################################"
echo ""

/bin/bash "$BASEDIR/requirements_installation.sh"
requirements_result=$?
case "$requirements_result" in
    0) ;;
    90|91) exit "$requirements_result" ;;
    *) exit "$DL4ME_STATUS_PREREQUISITE_FAILED" ;;
esac

echo ""
echo "################################"
echo ""

# Get the preferences choosen by the user, if they where choosen, if not the default
if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    containerisation="Docker"
    update="-"
    clean="-"
else
    containerisation=$(awk -F' : ' '$1 == "containerisation" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
    update=$(awk -F' : ' '$1 == "update" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
    clean=$(awk -F' : ' '$1 == "clean" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
fi

# Check if the Docker daemon is running, if Docker option is chose
if [[ "$containerisation" == "Docker"* ]]; then
    if ! docker info &> /dev/null; then
        if [[ "${DL4ME_WINDOWS_WRAPPER:-0}" == "1" ]]; then
            echo ""
            echo "------------------------------------"
            echo "Docker Desktop was verified as running by the Windows preflight, but"
            echo "Docker is not accessible to the current Ubuntu user."
            echo ""
            echo "This is a WSL Docker-access/integration problem, not a stopped Docker daemon."
            echo "Run Windows_launch.bat again so its Docker user-access check can diagnose"
            echo "and, for the standard docker-group case, repair the Linux socket permission."
            echo "------------------------------------"
            exit "$DL4ME_STATUS_PREREQUISITE_FAILED"
        fi
        /bin/bash "$BASEDIR/pre_build_launch/check_docker_daemon.sh" || exit "$DL4ME_STATUS_PREREQUISITE_FAILED"
    fi
fi

# Check if the update option has been selected and run the script if so
if [[ "$update" == "Automatically"* || "$update" == "Ask first"* ]]; then
    /bin/bash "$BASEDIR/pre_build_launch/update_dl4miceverywhere.sh" "0" "$flag_gui"
    
    updated=$?
    if [ "$updated" -eq "$DL4ME_STATUS_UPDATE_COMPLETE" ]; then
        exit "$DL4ME_STATUS_UPDATE_COMPLETE"
    fi
fi

# Check if the clean option has been selected and run the script if so
if [[ "$clean" == "Automatically"* || "$clean" == "Ask first"* ]]; then
    if [[ "$clean" == "Ask first"* ]]; then
        flag_clean=$(wish "$BASEDIR/../tcl_tools/oneline_yes_no_gui.tcl" "Clean DL4MicEverywhere Docker resources" "Remove unused DL4MicEverywhere-labelled Docker containers, images, and networks older than 24 hours? Other Docker resources, Docker volumes, and shared build cache will be preserved.")
        # flag_clean == 2 --> Yes
        # flag_clean == 3 --> No
    fi
   
    if [[ "$clean" == "Automatically"* || "${flag_clean:-0}" -eq 2 ]]; then
        if ! /bin/bash "$BASEDIR/pre_build_launch/clean_docker.sh"; then
            echo ""
            echo "WARNING: Docker space cleanup could not be completed."
            echo "This cleanup is optional, so DL4MicEverywhere will continue normally."
            echo "No Docker volumes are removed by this cleanup policy."
            echo ""
        fi
    fi 
fi
