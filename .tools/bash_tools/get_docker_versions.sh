#!/bin/bash

# Get the basedir
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1

# Import safe YAML value loader
source "$BASEDIR/get_yaml_args.sh"

notebook_name=$1

# Extract information from the cached versionings
load_yaml_args_from_file "$BASEDIR/../.cache/.cache_versioning" "var_" || exit 1

# Extract the version list from the cached versioning
non_dot_notebook_name="$(echo "$notebook_name" | tr . _ | tr - _ )"
notebook_variable="var_${non_dot_notebook_name}_version_list"
version_list=${!notebook_variable}

# Return the version list
echo $version_list