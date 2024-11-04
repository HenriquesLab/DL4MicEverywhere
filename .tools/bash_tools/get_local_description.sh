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

local_description="$config_dl4miceverywhere_description"

echo $local_description