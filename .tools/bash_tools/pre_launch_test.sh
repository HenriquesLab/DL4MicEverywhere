#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")
flag_gui="$1"

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

/bin/bash "$BASEDIR/requirements_installation.sh" || exit 1

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
        /bin/bash "$BASEDIR/pre_build_launch/check_docker_daemon.sh" || exit 1
    fi
fi

# Check if the update option has been selected and run the script if so
if [[ "$update" == "Automatically"* || "$update" == "Ask first"* ]]; then
    /bin/bash "$BASEDIR/pre_build_launch/update_dl4miceverywhere.sh" "0" "$flag_gui"
    
    updated=$? # Gets if the repository has been updated
    if [[ "$updated" == "1" ]]; then
        exit 1
    fi
fi

# Check if the clean option has been selected and run the script if so
if [[ "$clean" == "Automatically"* || "$clean" == "Ask first"* ]]; then
    if [[ "$clean" == "Ask first"* ]]; then
        flag_clean=$(wish "$BASEDIR/../tcl_tools/oneline_yes_no_gui.tcl" "Clean Docker Dekstop" "Would you like to leverage space on Docker Desktop application?")
        # flag_clean == 2 --> Yes
        # flag_clean == 3 --> No
    fi
   
    if [[ "$clean" == "Automatically"* || "$flag_clean" -eq 2 ]]; then
        /bin/bash "$BASEDIR/pre_build_launch/clean_docker.sh" || exit 1
    fi 
fi
