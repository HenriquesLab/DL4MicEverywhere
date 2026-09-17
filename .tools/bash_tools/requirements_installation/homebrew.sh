#!/bin/bash
set -e

echo "Installing Homebrew..."

# Homebrew's official installer supports non-interactive mode through this
# environment variable. DL4MicEverywhere discovers the supported Homebrew
# prefixes directly instead of executing generated shell environment code.
export NONINTERACTIVE=1

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [ -x /opt/homebrew/bin/brew ]; then
    /opt/homebrew/bin/brew --version >/dev/null
elif [ -x /usr/local/bin/brew ]; then
    /usr/local/bin/brew --version >/dev/null
elif command -v brew >/dev/null 2>&1; then
    brew --version >/dev/null
else
    echo "ERROR: Homebrew installer completed but brew could not be found." >&2
    exit 1
fi
