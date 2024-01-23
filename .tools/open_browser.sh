#!/bin/bash

# Get the url to launch.sh from the first argument
url=$1

echo "open_browser.sh: $url"

# Wait 10 seconds to launch the browser
sleep 5

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open $url
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    open $url
elif [[ "$OSTYPE" == "msys*" ]]; then
    # Windows
    start $url
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

# Exit with success
exit 0


