#!/bin/bash

# Function to parse and read the configuration yaml file
function get_yaml_args_from_file {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      value = $3;

      # Remove inline comments only if they are at the beginning of a line or after whitespace
      gsub(/[[:space:]]#.*/, "", value);

      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, value);
      }
   }'
}

function get_yaml_args_from_url {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   curl -s $1 | 
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      value = $3;

      # Remove inline comments only if they are at the beginning of a line or after whitespace
      gsub(/[[:space:]]#.*/, "", value);

      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, value);
      }
   }'
}

# $1 = $basedir
# $2 = $selectedFolder
# $3 = $notebook_name

# Get the local version on the configuration.yaml
eval $(get_yaml_args_from_file "$1/notebooks/$2/$3/configuration.yaml")

local_notebook_version="$config_dl4miceverywhere_notebook_version"
local_dl4miceverywhere_version="$config_dl4miceverywhere_dl4miceverywhere_version"
local_description="$config_dl4miceverywhere_description"

# Get the remote version on the configuration.yaml (on DL4MicEverywhere repository)
eval $(get_yaml_args_from_url https://raw.githubusercontent.com/HenriquesLab/DL4MicEverywhere/blob/main/notebooks/$2/$3/configuration.yaml)

# Compare the local and remote versions to check if there is an update.
# Different cases:
# 0: the notebook has the same version
# 1: the notebook doesn't have the same version
if [ $local_notebook_version == $config_dl4miceverywhere_notebook_version ]; then
   echo 0
else
   echo 1
fi


# Compare the local and remote versions to check if there is an update.
# Different cases:
# 2: local configuration does not have dl4miceverywhere version
# 3: online configuration does not have dl4miceverywhere version
# 0: both configurations have dl4miceverywhere version and they are the same
# 1: both configurations have dl4miceverywhere version but the versions are not the same
if [ -z "$local_dl4miceverywhere_version" ]; then
   echo 2
else
   if [ -z "$config_dl4miceverywhere_dl4miceverywhere_version" ]; then
      echo 3
   else
      if [ $local_dl4miceverywhere_version == $config_dl4miceverywhere_dl4miceverywhere_version ]; then
         echo 0
      else
         echo 1
      fi
   fi 
fi

echo $local_description