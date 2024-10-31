
#!/bin/bash
BASEDIR=$1

function save_settings {
    echo "containerization : $1
update : $2
clean : $3" > $BASEDIR/.tools/.cache_settings
}

if [ ! -f $BASEDIR/.tools/.cache_settings ]; then
    echo Not exist
    # If the settings cache does not exist, run the initial settings window
    settings=$(wish $BASEDIR/.tools/tcl_tools/menubar/initial_settings.tcl $BASEDIR)
else    
    echo Exist
    # Otherwise, run the regular settings window
    settings=$(wish $BASEDIR/.tools/tcl_tools/menubar/settings.tcl $BASEDIR)
fi

if [ -z "$settings" ]; then
    # No arguments were provided, this means that the GUI has been closed, so close the terminal
    exit 1
fi

IFS=$'\n' read -d '' -r -a strarr <<<"$settings"

containerization="${strarr[0]}"
update="${strarr[1]}"
clean="${strarr[2]}"

save_settings "$containerization" "$update" "$clean"