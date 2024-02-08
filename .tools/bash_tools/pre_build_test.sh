#!/bin/bash

# verlte() {
#     printf '%s\n' "$1" "$2" | sort -C -V
# }

# desired_version=25

# # Check if docker is installed
# if [[ $(which docker) ]]; then
#     # Check if docker daemon is running
#     if ( docker stats --no-stream  &> /dev/null ); then

#         # Check if docker version is good
#         # docker_version=$(docker version --format '{{.Server.Version}}')
#         # verlte $desired_version $docker_version && good_version=1 || good_version=0

#         # if [ "$good_version" -eq 1 ]; then
#         #     echo "Docker version $docker_version is good."
#         #     exit 0
#         # else
#         #     echo "Docker version $docker_version is not good. You need to update to $desired_version or higher."
#         #     exit 1
#         # fi
#         exit 0
#     else
#         echo "Docker daemon is not running."
#         exit 1
#     fi
# else
#     echo "Docker is not installed."
#     exit 1
# fi

# docker_owner=$(ls -ld ~/.docker | grep $(whoami))

# if [ "$docker_owner" == "" ]; then
#     echo "You are not owner of ~/.docker. Please enter the password to allow the access to ~/.docker and with this run Docker without root access."
#     sudo chown -R $(whoami) ~/.docker
# fi
