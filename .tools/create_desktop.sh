#!/bin/bash

# Get the base directory of DL4MicEveywhere repository
BASEDIR=$(dirname "$(readlink -f "$0")")
# Get the directory of the desktop folder
DESKTOPDIR=$(xdg-user-dir DESKTOP)

# Create the double-click launching desktop file
echo "[Desktop Entry]
Type=Application
Name=DL4MicEverywhere
Exec=$BASEDIR/../Linux_launch.sh
Terminal=true
Icon=$BASEDIR/../docs/logo/dl4miceverywhere-logo-small.png" > $DESKTOPDIR/DL4MicEverywhere.desktop

# Allow execution
chmod a+x $DESKTOPDIR/DL4MicEverywhere.desktop
