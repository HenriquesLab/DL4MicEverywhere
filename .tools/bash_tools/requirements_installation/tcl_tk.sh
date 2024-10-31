
echo "Installing TCL/TK..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sudo apt-get -y update
    sudo apt -y update
    sudo apt -y upgrade
    sudo apt-get -y install tcl
    sudo apt-get -y install tk

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    brew uninstall tcl-tk
    brew install tcl-tk

elif [[ "$OSTYPE" == "msys*" ]]; then
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