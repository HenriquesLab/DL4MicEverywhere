#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# Import get_yaml_args_from_file
source "$BASEDIR/get_yaml_args.sh"

# Extract information from the cached versionings
eval $(get_yaml_args_from_file "$BASEDIR/../../construct.yaml" "var_")

# Extract dl4miceverywhere version
dl4miceverywhere_version="$var_version"

# Return the version list
echo $dl4miceverywhere_version