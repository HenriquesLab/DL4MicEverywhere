#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# Function to parse and read the configuration yaml file
function get_yaml_args_from_file {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  "$1" |
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

function save_versioning {
    local notebook_name="$1"

    local list_versions=""
    local list_tag=""

    local paired_version_tag=""

    # Flag to control if its the first notebooks and a (latest) tag needs to be added
    local flag_first_time=1

    local page=1
    # We will look through all the pages on docker hub
    while true; do
        # Get the content in the page that we are
        local response=$(curl -s "https://hub.docker.com/v2/repositories/henriqueslab/dl4miceverywhere/tags?page_size=100&page=$page")
        # Extract the tag name of the docker image
        local tags=$(echo "$response" | grep -o '"name":"[^"]*' | sed 's/"name":"//')

        # Break if no more tags are returned
        if [ -z "$tags" ]; then
            break
        fi
        
        # Filter the tags to only get the ones with the provided name 
        local desired_tags=$(echo "$tags" | grep "^$notebook_name" | grep -E '[zbe][0-9]+\.[0-9]+\.[0-9]+-d[0-9]+\.[0-9]+\.[0-9]+$')
        # Extract the version number
        local version_number=$(echo "$desired_tags" | grep -o '[zbe][0-9]\+\.[0-9]\+\.[0-9]\+')

        # We are going to iterate over the multiple tags in the same page
        ## First, save previous the delimiter
        saveIFS="$IFS"
        ## Then define new delimiter
        IFS=$'\n'
        ## Read the split versions into an array using above IFS
        local version_arr=($version_number)
        local tag_arr=($desired_tags)
        # Return IFS back to original
        IFS="$saveIFS"
        
        ## Iterate through those values
        for i in "${!version_arr[@]}"; do
            local version=${version_arr[i]:1}
            local tag=${tag_arr[i]}

            # Check if the version is already on the list
            if [[ $list_versions != *"${version}"* ]]; then
                # It might happen that same notebook versions is available for 
                # different DL4MicEverywhere versions, this way we will take the
                # latest DL4MicEverywhere version 
                
                # Bash variables cannot have dots, that is why the dots are replaced with '-'
                local non_dot_version="$(echo "$version" | tr . _)"

                # The firt time, initialize the lists and add latest to the version
                if [ "$flag_first_time" -eq 1 ]; then
                    local list_versions="${version}(latest)"
                    local list_tag="${tag}"

                    local flag_first_time=0
                else
                    local list_versions="${list_versions} ${version}"
                    local list_tag="${list_tag} ${tag}"
                fi
                local paired_version_tag="${paired_version_tag}\t${non_dot_version}: ${tag}\n"
            fi
        done

        local page=$((page + 1))
    done

    echo -e "\tversion_list: '$list_versions'" >> "$cache_file"
    echo -e "\ttag_list: '$list_tag'" >> "$cache_file"
    echo -e "$paired_version_tag" >> "$cache_file"

}

echo "Storing the possible versions of each Docker image."
echo "This might take some minutes ..."

# Create the cache file
cache_file="$BASEDIR/../.cache/.cache_versioning"
mkdir -p "$BASEDIR/../.cache/" && echo "" > "$cache_file"

# Iterate through notebook types
for notebook_type in "$BASEDIR"/../../notebooks/*; do
    # Iterate through each notebook
    for notebook_folder in "$notebook_type"/*; do
        if [ -d "$notebook_folder" ]; then
            # Extract the notebook url from the configuration file
            eval $(get_yaml_args_from_file "$notebook_folder/configuration.yaml")
            notebook_url="$config_dl4miceverywhere_notebook_url"

            # Get the notebook name (which is related to the docker image tag)
            notebook_name=$(basename $notebook_url)
            notebook_name=${notebook_name%".ipynb"}
            notebook_name=$(echo $notebook_name | tr '[:upper:]' '[:lower:]')

            fixed_notebook_folder="$(echo "$notebook_folder" | tr . _ | tr - _)"

            echo "$(basename "$fixed_notebook_folder"):" >> "$cache_file"

            save_versioning "$notebook_name"
        fi
    done
done