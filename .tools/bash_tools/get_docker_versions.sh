#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# Import get_yaml_args_from_file
source "$BASEDIR/get_yaml_args.sh"

notebook_name=$1

# Extract information from the cached versionings
eval $(get_yaml_args_from_file "$BASEDIR/../.cache/.cache_versioning" "var_")

# Extract the version list from the cached versioning
non_dot_notebook_name="$(echo "$notebook_name" | tr . _ | tr - _ )"
notebook_variable="var_${non_dot_notebook_name}_version_list"
version_list=${!notebook_variable}

# Return the version list
echo $version_list