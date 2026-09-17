#!/bin/bash

# Get the basedir
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1

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