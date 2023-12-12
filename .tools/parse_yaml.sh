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
         echo 1
      fi
   else
      eval "$variable_name=\$$config_variable_name"
   fi
   echo 0
}

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

# Check the parsed variables
local_notebook_version_exists=$(check_parsed_argument notebook_version)
if [ "$local_notebook_version_exists" -eq 1 ]; then
   exit 1
fi
local_dl4miceverywhere_version_exists=$(check_parsed_argument dl4miceverywhere_version)
# if [ "$local_dl4miceverywhere_version_exists" -eq 1 ]; then
#    echo "dl4miceverywhere_version parameter is not specified on the configuration yaml."
# fi

local_notebook_version=$notebook_version
local_dl4miceverywhere_version=$dl4miceverywhere_version

# Also get the desctiption of the model
local_description=$description

# Get the remote version on the configuration.yaml (on DL4MicEverywhere repository)
eval $(get_yaml_args_from_url https://raw.githubusercontent.com/HenriquesLab/DL4MicEverywhere/versioning/notebooks/$2/$3/configuration.yaml)

# Check the parsed variables
notebook_version_exists=$(check_parsed_argument notebook_version)
if [ "$notebook_version_exists" -eq 1 ]; then
   exit 1
fi
dl4miceverywhere_version=$(check_parsed_argument dl4miceverywhere_version)

# Compare the local and remote versions to check if there is an update.
# Different cases:
# 0: the notebook has the same version
# 1: the notebook doesn't have the same version
if [ $local_notebook_version == $notebook_version ]; then
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
if [ "$local_dl4miceverywhere_version_exists" -eq 1 ]; then
   echo 2
else
   if [ "$dl4miceverywhere_version_exists" -eq 1 ]; then
      echo 3
   else
      if [ $local_dl4miceverywhere_version == $dl4miceverywhere_version ]; then
         echo 0
      else
         echo 1å
      fi
   fi 
fi

echo $local_description