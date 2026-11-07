#!/bin/bash

# Get the sleep time and URL.
sleep_time=$1
url=$2

sleep "$sleep_time"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v systemd-detect-virt >/dev/null 2>&1 && [[ "$(systemd-detect-virt 2>/dev/null)" == "wsl"* ]]; then
        # Open the URL with Windows PowerShell directly. -NoProfile prevents a
        # user's PowerShell profile/execution-policy settings from producing
        # unrelated warnings in the DL4MicEverywhere terminal.
        # WSL only shares Linux environment variables with Windows programs when
        # they are listed in WSLENV; without it PowerShell receives no URL.
        # Passing the URL through the environment (not the command line) keeps
        # characters such as '&' or '?' from being interpreted by PowerShell.
        DL4ME_BROWSER_URL="$url" WSLENV="DL4ME_BROWSER_URL${WSLENV:+:$WSLENV}" \
            powershell.exe -NoProfile -NonInteractive \
            -Command 'Start-Process -FilePath $env:DL4ME_BROWSER_URL'
    else
        xdg-open "$url"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url"
elif [[ "$OSTYPE" == "msys"* ]]; then
    start "$url"
else
    echo ""
    echo "------------------------------------"
    echo "Unsupported OS: $OSTYPE"
    echo "We only provide support for Windows, MacOS and Linux."
    read -r -p "Press enter to close the terminal."
    echo "------------------------------------"
    exit 1
fi

exit 0
