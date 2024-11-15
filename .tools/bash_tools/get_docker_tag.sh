#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# Import get_yaml_args_from_file
source "$BASEDIR/get_yaml_args.sh"

notebook_name="$1"
notebook_version="$2"

# Extract information from the cached versionings
eval $(get_yaml_args_from_file "$BASEDIR/../.cache/.cache_versioning" "var_")
# Extract the version list from the cached versioning
non_dot_notebook_name="$(echo "$notebook_name" | tr . _ | tr - _)"
# The version might have `(latest)` at the end, if so remove it
non_dot_notebook_version="$(echo "$notebook_version" | tr . _ | tr - _  | sed -e "s/(latest)$//")"
notebook_variable="var_${non_dot_notebook_name}_${non_dot_notebook_version}"

notebook_tag=${!notebook_variable}

echo $notebook_tag