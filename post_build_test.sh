#!/bin/bash


# Find a usable port
aux_port=8888
while ( ! lsof -i:$aux_port )
do
    aux_port=$((aux_port+1))
done

echo "Using port $aux_port"


# Remove dangling images (without tags)
docker rmi $(docker images -f “dangling=true” -q --no-trunc)