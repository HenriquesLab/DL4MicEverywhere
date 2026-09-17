#!/bin/bash

# Get the base directory of DL4MicEveywhere repository
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/bash_tools/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1
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
