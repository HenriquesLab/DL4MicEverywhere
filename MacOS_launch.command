#!/bin/bash

# Get the directory of the script
BASEDIR=$(dirname "$(readlink -f "$0")")
            
# Esecute the bash with the launch script
/bin/bash $BASEDIR/Linux_launch.sh

# Close the terminal
(sleep 0.1 ; osascript -e 'tell application "Terminal" to quit') &