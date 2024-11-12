#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")

function save_preferences {
    mkdir -p "$BASEDIR/../.cache"
    echo "containerisation : $1
update : $2
clean : $3" > "$BASEDIR/../.cache/.cache_preferences"
}

if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    # If the preferences cache does not exist, run the initial preferences window
    preferences=$(wish "$BASEDIR/../tcl_tools/menubar/initial_preferences.tcl" "$BASEDIR")
else    
    # Otherwise, run the regular preferences window
    preferences=$(wish "$BASEDIR/../tcl_tools/menubar/preferences.tcl" "$BASEDIR")
fi

if [ -z "$preferences" ]; then
    # No arguments were provided, this means that the GUI has been closed, so close the terminal
    exit 0
fi

IFS=$'\n' read -d '' -r -a strarr <<<"$preferences"

containerisation="${strarr[0]}"
update="${strarr[1]}"
clean="${strarr[2]}"

save_preferences "$containerisation" "$update" "$clean"