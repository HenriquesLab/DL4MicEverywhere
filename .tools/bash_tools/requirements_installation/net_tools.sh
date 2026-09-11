#!/bin/bash
set -e

echo "Installing net-tools..."

# Refresh package metadata, but do not upgrade the operating system.
sudo apt-get update
sudo apt-get install -y net-tools
