#!/bin/bash
set -e

# Python is host-side tooling only: it generates/validates deterministic lockfiles.
# It is not part of the Docker image environment being locked.
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required to install Python for dependency lock generation." >&2
        exit 1
    fi
    brew install python
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update
    sudo apt-get install -y python3 python3-venv
else
    echo "Automatic Python installation is not supported on this host: $OSTYPE" >&2
    exit 1
fi
