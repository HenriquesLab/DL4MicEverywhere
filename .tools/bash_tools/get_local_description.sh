#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# Import safe YAML value loaders
source "$BASEDIR/get_yaml_args.sh"

## The input parameters
# $1 = $basedir
# $2 = $selectedFolder
# $3 = $notebook_name

# Get the local version on the configuration.yaml
load_yaml_args_from_file "$1/notebooks/$2/$3/configuration.yaml" || exit 1

local_description="$config_dl4miceverywhere_description"

echo "$local_description"