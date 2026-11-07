#!/bin/bash

# Get the basedir
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1

# Import safe YAML value loader
source "$BASEDIR/get_yaml_args.sh"

# Extract information from the cached versionings
load_yaml_args_from_file "$BASEDIR/../../construct.yaml" "var_" || exit 1

# Extract dl4miceverywhere version
dl4miceverywhere_version="$var_version"

# Return the version list
echo $dl4miceverywhere_version