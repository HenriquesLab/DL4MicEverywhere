#!/bin/bash
set -e

echo "Installing xdg-utils..."

# Refresh package metadata, but do not upgrade the operating system.
sudo apt-get update
sudo apt-get install -y xdg-utils
