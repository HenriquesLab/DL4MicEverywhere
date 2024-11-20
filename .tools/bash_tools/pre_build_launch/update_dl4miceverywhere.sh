#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")
already_asked=$1

if [ -f "$BASEDIR/../../.cache/.cache_preferences" ]; then
    # If this script is called, this file should always exist
    update=$(awk -F' : ' '$1 == "update" {print $2}' "$BASEDIR/../../.cache/.cache_preferences")
else
    echo "Something went wrong when trying to update DL4MicEverywhere."
    exit 0
fi

# Check if Git is installed
if command -v git &> /dev/null; then
    # Get the name of the local branch
    branch_name=$(git branch --show-current)
    # Get the latest commit locally
    local_commit=$(git rev-parse HEAD)
else
    # Get the name of the local branch
    branch_name=$(cat .git/HEAD | sed -n 's|^ref: refs/heads/||p')
    # Get the latest commit locally
    local_commit=$(cat .git/refs/heads/$branch_name)
fi

# Get the latest commit on the DL4MicEverywhere's online repository
online_commit=$(curl -s "https://api.github.com/repos/HenriquesLab/DL4MicEverywhere/commits/${branch_name}" | grep '"sha"' | head -1 | cut -d '"' -f 4)

if [[ "$already_asked" == "1" ]]; then 
    # Check if an update is need
    if [[ "$local_commit" == "$online_commit" ]]; then
        # Tell the user that everything is up to date
        # One line GUI with just Done button (first argument the title, second one the sentece)
        wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "Up to date" "You are up to date!"
    else
        # In case is needed, ask the user if they want to update
        update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked")
        
        # In case the user closed the window, it will not be updated
        if [ -z $update_flag ]; then
            update_flag=1
        fi
    fi
elif [[ "$local_commit" != "$online_commit" && "$update" == "Ask first"* ]]; then
        # It will enter on pre_build only if an update is needed and the user has "Ask first" as preference
        update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked")
        
        # In case the user closed the window, it will not be updated
        if [ -z $update_flag ]; then
            update_flag=1
        fi
else 
    # Otherwise, no udpate
    update_flag=1
fi

if [[ "$update" == "Automatically"* || "$update_flag" -eq 2 ]]; then

    if [[ "$already_asked" == "0" ]]; then echo "Checking DL4MicEverywhere version ..."; fi
    # Check if the commits match
    if [[ "$local_commit" == "$online_commit" ]]; then
        if [[ "$already_asked" == "0" ]]; then echo "You are up to date!"; fi
    else
        if [[ "$already_asked" == "0" ]]; then echo "DL4MicEverywhere will be updated ..."; fi
        if command -v git &> /dev/null; then
            # In case they don't match, update it with git pull if you have git installed
            git pull
        else
            # Otherwise update it using
            curl -L -o update.pack https://github.com/HenriquesLab/DL4MicEverywhere.git/info/refs?service=git-upload-pack
        fi

        # if [[ "$already_asked" == "0" ]]; then 
        #     echo ""
        #     echo "------------------------------------"
        #     echo "Succesfully udpated! The window will be closed, please open it again."
        #     read -p "Press enter to close the terminal."
        #     echo "------------------------------------" 
        # else
        #     wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "Succesfully updated" "Succesfully udpated! The window will be closed, please open it again."
        # fi

        wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "Succesfully updated" "Succesfully udpated! The window will be closed, please open it again."
        exit 1
    fi

    if [[ "$already_asked" == "0" ]]; then 
        echo ""
        echo "################################"
        echo ""
    fi
fi