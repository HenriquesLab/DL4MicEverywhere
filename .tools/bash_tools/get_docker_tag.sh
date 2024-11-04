#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

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

notebook_name=$1
notebook_version=$2

# Extract information from the cached versionings
eval $(get_yaml_args_from_file "$BASEDIR/../.cache/.cache_versioning")

# Extract the version list from the cached versioning
non_dot_notebook_version="$(echo "$notebook_version" | tr . _)"
notebook_variable=${notebook_name}_${non_dot_notebook_version}
notebook_tag=${!notebook_variable}

echo $notebook_tag