#!/bin/bash

# This script checks for root access and Docker installation on Unix-like systems
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  # Verify if the script is run as root, which is required for Docker to function correctly
  if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (by using sudo). Otherwise docker won't work properly."
    echo "Make sure to use the -E flag to preserve the environment variables when using ssh and X11"
    echo "E.g. sudo -E bash launch.sh"
    exit 1
  fi
fi

# Verify if Docker is installed on the system
if ! command -v docker &> /dev/null; then
  echo "Docker could not be found. Please install Docker."

  # Provide Docker installation instructions
  echo "Please follow the instructions at https://docs.docker.com/install/ to install Docker."
  
  # Terminate the script with a non-zero exit code
  exit 1 
fi

# Check if the Docker daemon is running
if ! docker info &> /dev/null; then
  echo "Error: Docker daemon is not running"
  exit 1 
fi