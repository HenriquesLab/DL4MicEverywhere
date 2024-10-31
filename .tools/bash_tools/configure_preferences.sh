
#!/bin/bash
BASEDIR=$(dirname "$(readlink -f "$0")")

function save_settings {
    echo "containerisation : $1
update : $2
clean : $3" > $BASEDIR/../.cache_settings
}

if [ ! -f $BASEDIR/../.cache_settings ]; then
    echo Not exist
    # If the settings cache does not exist, run the initial settings window
    settings=$(wish $BASEDIR/../tcl_tools/menubar/initial_settings.tcl $BASEDIR)
else    
    echo Exist
    # Otherwise, run the regular settings window
    settings=$(wish $BASEDIR/../tcl_tools/menubar/settings.tcl $BASEDIR)
fi

if [ -z "$settings" ]; then
    # No arguments were provided, this means that the GUI has been closed, so close the terminal
    exit 1
fi

IFS=$'\n' read -d '' -r -a strarr <<<"$settings"

containerisation="${strarr[0]}"
update="${strarr[1]}"
clean="${strarr[2]}"

save_settings "$containerisation" "$update" "$clean"