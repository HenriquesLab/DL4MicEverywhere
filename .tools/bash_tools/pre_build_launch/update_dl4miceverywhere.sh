#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")
already_asked=$1
flag_gui="$2"

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
        if [ "$flag_gui" -eq 1 ]; then 
            # One line GUI with just Done button (first argument the title, second one the sentece)
            wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "Up to date" "You are up to date!"
        else
            echo "You are up to date!"
        fi
    else
        # In case is needed, ask the user if they want to update
        if [ "$flag_gui" -eq 1 ]; then 
            update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked")
        else
            echo "Are you sure that you want to update DL4MicEverywhere?"
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) flag_build=2; break;;
                    No ) flag_build=1; break;;
                esac
            done
        fi
        # In case the user closed the window, it will not be updated
        if [ -z $update_flag ]; then
            update_flag=1
        fi
    fi
elif [[ "$local_commit" != "$online_commit" && "$update" == "Ask first"* ]]; then
        # It will enter on pre_build only if an update is needed and the user has "Ask first" as preference
        if [ "$flag_gui" -eq 1 ]; then 
            update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked")
        else
            echo "Your DL4MicEverywhere version seems to not be up to date."
            echo "Do you want to update DL4MicEverywhere?"
            select yn in "Yes" "No"; do
                case $yn in
                    Yes ) flag_build=2; break;;
                    No ) flag_build=1; break;;
                esac
            done
        fi

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

        if [ "$flag_gui" -eq 1 ]; then 
            wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "Succesfully updated" "Succesfully udpated! DL4MicEverywhere will be closed, please open it again."
        else
            echo ""
            echo "------------------------------------"
            echo "Succesfully udpated! The window will be closed, please open it again."
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
        fi
        exit 1
    fi

    if [[ "$already_asked" == "0" ]]; then 
        echo ""
        echo "################################"
        echo ""
    fi
fi