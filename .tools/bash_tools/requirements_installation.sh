#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")

any_installation_flag=0

# Check if hombrew is installed on your MacOs and otherwise install it
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then

        /bin/bash $BASEDIR/requirements_installation/homebrew.sh || exit 1

        if ! command -v brew &> /dev/null; then
            echo ""
            echo "------------------------------------"
            echo -e "\033[0;31 Homebrew installation failed. \033[0m"
            echo "Please try again or follow the requirements installation we provide:"
            echo "https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/REQUIREMENTS_INSTALLATION.md"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        else
            any_installation_flag=1
        fi
    else
        echo "Homebrew already installed."
    fi
fi

# Verify if tcl/tk is installed on the system and otherwise install it
if ! command -v wish &> /dev/null; then
    
    /bin/bash $BASEDIR/requirements_installation/tcl_tk.sh || exit 1

    if ! command -v wish &> /dev/null; then
        echo ""
        echo "------------------------------------"
        echo -e "\033[0;31 Wish (TCL/TK) installation failed. \033[0m"
        echo "Please try again or follow the requirements installation we provide:"
        echo "https://github.com/HenriquesLab/DL4MicEverywhere/blob/main/docs/REQUIREMENTS_INSTALLATION.md"
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    else
        any_installation_flag=1
    fi
else
    echo "TCL/TK already installed."
fi 

# Verify if xdg-open is installed on the system and otherwise install it
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v xdg-open &> /dev/null; then 

        /bin/bash $BASEDIR/requirements_installation/xdg_utils.sh || exit 1

        if ! command -v xdg-open &> /dev/null; then 
            echo ""
            echo "------------------------------------"
            echo -e "\033[0;31 xdg-utils installation failed. \033[0m"
            echo "Please try again or follow the installation instructions on: https://installati.one/install-xdg-utils-ubuntu-20-04/"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        else
            any_installation_flag=1
        fi
    else
        echo "xdg-utils already installed."
    fi
fi

# Verify if netstat is installed on the WSL and otherwise install it
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$(systemd-detect-virt)" == "wsl"* ]]; then
        # Linux inside the Windows Subsystem for Linux needs to export/link the start command
        if ! command -v netstat &> /dev/null; then 
            
            /bin/bash $BASEDIR/requirements_installation/net_tools.sh || exit 1

            if ! command -v netstat &> /dev/null; then 
                echo ""
                echo "------------------------------------"
                echo -e "\033[0;31 net-tools installation failed. \033[0m"
                echo "Please try again or follow the installation instructions on:"
                echo "https://installati.one/install-net-tools-ubuntu-20-04/"
                read -p "Press enter to close the terminal."
                echo "------------------------------------" 
                exit 1
            else
                any_installation_flag=1
            fi
        else
            echo "net-tools already installed."
        fi
    fi
fi


if [ ! -f $BASEDIR/../.cache/.cache_preferences ]; then
    # It shouldn't enter here, because at this point the .cache_preferences file
    # should be created. But just in case, Docker is the default containerisation sysyem.
    containerisation="Docker"
else
   containerisation=$(awk -F' : ' '$1 == "containerisation" {print $2}' $BASEDIR/../.cache/.cache_preferences)
fi

if [[ "$containerisation" == "Docker"* ]]; then
    # Verify if Docker is installed on the system and otherwise install it
    if ! command -v docker &> /dev/null; then
        
        /bin/bash $BASEDIR/requirements_installation/docker.sh || exit 1
        
        if ! command -v docker &> /dev/null; then
            echo ""
            echo "------------------------------------"
            echo -e "\033[0;31 Docker installation failed. \033[0m"
            echo "Please try again or follow the installation instructions on:"
            echo "https://installati.one/install-net-tools-ubuntu-20-04/"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        else
            any_installation_flag=1
            # Restart Docker service to ensure that works well
            # sudo service docker restart
        fi 
    else
        echo "Docker already installed."
    fi

elif [[ "$containerisation" == "Singularity"* ]]; then

    # Verify if Singularity is installed on the system and otherwise install it
    if ! command -v singularity &> /dev/null; then
        
        /bin/bash $BASEDIR/requirements_installation/singularity.sh || exit 1
        
        if ! command -v singularity &> /dev/null; then
            echo ""
            echo "------------------------------------"
            echo -e "\033[0;31 Docker installation failed. \033[0m"
            echo "Please try again or follow the installation instructions on:"
            echo "https://installati.one/install-net-tools-ubuntu-20-04/"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        else
            any_installation_flag=1
            # Restart Docker service to ensure that works well
            # sudo service docker restart
        fi 
    else
        echo "Singularity already installed."
    fi

else
    echo ""
    echo "------------------------------------"
    echo -e "\033[0;31 Something failed while choosing the containerisation system. \033[0m"
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
fi


# Check if any installation has been done and if so recommend the user to restart the computer
if [[ "$any_installation_flag" -ne 0 ]]; then

    echo ""
    echo "------------------------------------"
    echo "All dependencies have been successfully installed!"
    echo "It's recommended to restart your computer to apply all changes."
    echo "------------------------------------" 

    # Show the window with the option to restart
    requirements_flag=$(wish $BASEDIR/../tcl_tools/restart_computer.tcl)
    if [[ "$requirements_flag" == s2 ]]; then
        # Restart the computer at the moment of clicking
        sudo shutdown -r now
    else
        exit 1
    fi
fi