#!/bin/bash

echo "Installing Homebrew..."

# Export non interactive variable to avoid asking for input
exportNONINTERACTIVE=1 

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >>  ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
