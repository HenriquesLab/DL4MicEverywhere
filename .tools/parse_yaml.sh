#!/bin/bash

# Function to parse and read the configuration yaml file
function get_yaml_args {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# $1 = $basedir
# $2 = $selectedFolder
# $3 = $notebook_name

# Get the local version on the configuration.yaml
eval $(get_yaml_args "$1/notebooks/$2/$3/configuration.yaml")
local_version=$version

# Also get the desctiption of the model
local_description=$description

# Get the remote version on the configuration.yaml (on DL4MicEverywhere repository)
wget -q https://raw.githubusercontent.com/HenriquesLab/DL4MicEverywhere/main/notebooks/$2/$3/configuration.yaml
eval $(get_yaml_args "./configuration.yaml")
rm ./configuration.yaml

# Compare the local and remote versions to check if there is an update
if [ $version == $local_version ]; then
   echo 0
else
   echo 1
fi

echo $local_description