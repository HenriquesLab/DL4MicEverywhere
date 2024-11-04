
#!/bin/bash
BASEDIR=$(dirname "$(readlink -f "$0")")

if [ -f "$BASEDIR/../../.cache/.cache_preferences" ]; then
    # If this script is called, this file should always exist
    update=$(awk -F' : ' '$1 == "update" {print $2}' "$BASEDIR/../../.cache/.cache_preferences")
else
    echo "Something went wrong when trying to update DL4MicEverywhere."
    exit 0
fi

echo "Checking DL4MicEverywhere version ..."

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

# Check if the commits match
if [[ "$local_commit" == "$online_commit" ]]; then
    echo "You are up to date!"
else
    if command -v git &> /dev/null; then
        # In case they don't match, update it with git pull if you have git installed
        if [[ "$update" == "Ask first"* ]]; then
            # Check if you need to ask with a GUI
            update_flag=$(wish "$BASEDIR/../tcl_tools/update_gui.tcl")
        fi

        if [[ "$update" == "Automatically"* || "$update_flag" -ne 1 ]]; then
            git pull
        fi
    else
        # Otherwise update it using
        if [[ "$update" == "Ask first"* ]]; then
            # Check if you need to ask with a GUI
            update_flag=$(wish "$BASEDIR/../tcl_tools/update_gui.tcl")
        fi

        if [[ "$update" == "Automatically"* || "$update_flag" -ne 1 ]]; then
            curl -L -o update.pack https://github.com/HenriquesLab/DL4MicEverywhere.git/info/refs?service=git-upload-pack
        fi
    fi
fi

echo ""
echo "################################"
echo ""