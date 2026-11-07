#!/bin/bash
set -e

echo "Installing TCL/TK..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: install only the packages DL4MicEverywhere needs. Do not perform
    # a full distribution upgrade as part of application setup.
    sudo apt-get update
    sudo apt-get install -y tcl tk

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX: Homebrew can install or update the formula without first
    # uninstalling the user's existing Tcl/Tk installation.
    brew install tcl-tk

elif [[ "$OSTYPE" == "msys"* ]]; then
    # Windows
    echo "This is a Windows machine"
else
    echo ""
    echo "------------------------------------"
    echo "Unsupported OS: $OSTYPE"
    echo "We only provide support for Windows, MacOS and Linux."
    read -p "Press enter to close the terminal."
    echo "------------------------------------"
    exit 1
fi
