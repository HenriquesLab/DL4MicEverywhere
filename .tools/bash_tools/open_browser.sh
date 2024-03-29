#!/bin/bash

# Get the url to launch.sh from the first argument
url=$1

# Wait 10 seconds to launch the browser
sleep 5

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
        # Linux inside the Windows Subsystem for Linux needs to export/link the start command
        export BROWSER="powershell.exe /C start"
    fi
    xdg-open $url
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    open $url
elif [[ "$OSTYPE" == "msys*" ]]; then
    # Windows
    start $url
else
    echo ""
    echo "------------------------------------"
    echo "Unsupported OS: $OSTYPE"
    echo "We only provide support for Windows, MacOS and Linux."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
fi

# Exit with success
exit 0


