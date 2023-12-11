#!/bin/bash

# Function to check if a given argument exists or to rename it in case is needed
check_parsed_argument() {
    variable_name="$1"
    config_variable_name="config_dl4miceverywhere_$1"
    
    if [ -z "${!config_variable_name}" ]; then
        # If no config:dl4miceverywhere:$variable_name is on the configuration yaml
        # check if there is the old version with only $variable_name
        # in case that is neither there, raise an error
        if [ -z "${!variable_name}" ]; then
            echo "$variable_name parameter is not specified on the configuration yaml."
            exit 1
        fi
    else
        eval "$variable_name=\$$config_variable_name"
    fi

}

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
eval $(get_yaml_args "$1/notebooks/$2/$3/configuration.yaml")

# Check the parsed variables
check_parsed_argument notebook_url
check_parsed_argument requirements_url
check_parsed_argument cuda_version
check_parsed_argument ubuntu_version
check_parsed_argument python_version
check_parsed_argument sections_to_remove
check_parsed_argument notebook_version
check_parsed_argument dl4miceverywhere_version
check_parsed_argument description

local_notebook_version=$notebook_version
local_dl4miceverywhere_version=$dl4miceverywhere_version

# Also get the desctiption of the model
local_description=$description

# Get the remote version on the configuration.yaml (on DL4MicEverywhere repository)
wget -q https://raw.githubusercontent.com/HenriquesLab/DL4MicEverywhere/tree/versioning/notebooks/$2/$3/configuration.yaml
eval $(get_yaml_args "./configuration.yaml")
rm ./configuration.yaml

# Check the parsed variables
check_parsed_argument notebook_url
check_parsed_argument requirements_url
check_parsed_argument cuda_version
check_parsed_argument ubuntu_version
check_parsed_argument python_version
check_parsed_argument sections_to_remove
check_parsed_argument notebook_version
check_parsed_argument dl4miceverywhere_version
check_parsed_argument description

# Compare the local and remote versions to check if there is an update.
# Different cases:
# 0: both notebook and dl4miceverywhere have the same version
# 1: only notebook has the same version
# 2: only dl4miceverywhere has the same version
# 3: none have the same version
if [ $local_notebook_version == $notebook_version ]; then
   if [ $local_dl4miceverywhere_version == $dl4miceverywhere_version ]; then
      echo 0
   else
      echo 1
   fi
else
   if [ $local_dl4miceverywhere_version == $dl4miceverywhere_version ]; then
      echo 2
   else
      echo 3
   fi
fi

echo $local_description