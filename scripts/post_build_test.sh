#!/bin/bash

# Remove dangling images (without tags)
docker rmi $(docker images -f “dangling=true” -q --no-trunc)