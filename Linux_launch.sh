#!/bin/bash

# Get the basedir
BASEDIR=$(dirname "$(readlink -f "$0")")

# If no arguments are provided, set the GUI flag
if [ $# -eq 0 ]; then
    flag_gui=1
else 
    flag_gui=0
fi

# Run pre_launch_test.sh, stop if it fails
/bin/bash "$BASEDIR/.tools/bash_tools/pre_launch_test.sh" "$flag_gui" || exit 1

# Function with the text to describe the usage of the bash script
usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue

Welcome to DL4MicEverywhere!
Providing an easy way to apply deep learning to microscopy using interactive Jupyter notebooks.
DL4MicEverywhere enables you to build/pull and run a notebook docker image. 

Below, you'll find examples of the most basic usage case, as well as all the available options for a more advanced experience.

The most basic usage case involves providing three paths (these are always required):
 - The path to the configuration file 'configuration.yaml'.
 - The path to the folder containing the data for your notebook.
 - The path to the folder where you wish to save your notebook's results.

Code example:
    $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path -o output_path

Here is a list of all available arguments:
 -h      Display this help message and exit. (optional)
 -c      Path to the configuration file 'configuration.yaml'.   
 -d      Path to the folder containing the data for your notebook.
 -o      Path to the folder where you wish to save your notebook's results.
 -g      Flag to indicate if GPU should be used. (optional)
 -n      Path to a local notebook file 'notebook.ipynb'. (optional)
 -r      Path to a local requirements input file 'requirements.txt'. (optional)
 -t      Tag to be added to the docker image during building. (optional)
 -p      Port number where to open the notebook.
 -x      Flag to indicate if it is a test run. This allows for the printing of useful debugging information. (optional)

Code example:
    $(basename "${BASH_SOURCE[0]}") -c configuration_path -d dataset_path -o output_path [-h|t|g] [-n notebook_path] [-r requirements_path] 

EOF
  exit
}

# Function to check if a given argument exists or to rename it in case is needed
rename_parsed_argument() {
    variable_name="$1"
    config_variable_name="config_dl4miceverywhere_$1"
    eval "$variable_name=\$$config_variable_name"
}

check_parsed_argument() {
    variable_name="$1"
    config_variable_name="config_dl4miceverywhere_$1"
    
    if [ -z "${!config_variable_name}" ]; then
        if [ -z "${!variable_name}" ]; then
            # Close the terminal
            echo ""
            echo "------------------------------------"
            echo "$variable_name parameter is not specified on the configuration yaml."
            echo "Please specify the $variable_name parameter on the configuration yaml."
            echo "If the problem persists, please create an issue on GitHub:"
            echo "  https://github.com/HenriquesLab/DL4MicEverywhere/issues"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            exit 1
        fi
    else
        rename_parsed_argument $variable_name
    fi
}

function cache_gui {
    mkdir -p "$BASEDIR/.tools/.cache"
    echo "data_path : $1
result_path : $2
selected_folder : $3
selected_notebook : $4
config_path : $5
notebook_path : $6
requirements_path : $7
flag_gpu : $8
selected_version : $9
tag : ${10}
advanced_options : ${11}" > "$BASEDIR/.tools/.cache/.cache_gui"
}

# Record images created/downloaded through this launcher. The ID+tag pair lets
# the uninstaller remove custom tags safely without deleting an unrelated image
# that may later reuse the same tag.
track_managed_docker_image() {
    local image_ref="$1"
    local image_id
    local cache_file="$BASEDIR/.tools/.cache/.managed_docker_images"
    local tmp_file

    image_id=$(docker image inspect --format '{{.Id}}' "$image_ref" 2>/dev/null) || return 0

    mkdir -p "$BASEDIR/.tools/.cache"
    echo "$image_id|$image_ref" >> "$cache_file"

    tmp_file="${cache_file}.tmp"
    awk '!seen[$0]++' "$cache_file" > "$tmp_file" && mv "$tmp_file" "$cache_file"
}


# Import get_yaml_args_from_file
source "$BASEDIR/.tools/bash_tools/get_yaml_args.sh"

is_legacy_python() {
    case "$1" in
        3.5|3.6)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

select_dockerfile() {
    local gpu_enabled="$1"
    local python_version="$2"

    if [ "$gpu_enabled" -eq 1 ]; then
        if is_legacy_python "$python_version"; then
            echo "$BASEDIR/docker/Dockerfile.gpu.legacy"
        else
            echo "$BASEDIR/docker/Dockerfile.gpu.modern"
        fi
    else
        if is_legacy_python "$python_version"; then
            echo "$BASEDIR/docker/Dockerfile.legacy"
        else
            echo "$BASEDIR/docker/Dockerfile.modern"
        fi
    fi
}

# Let's define the default values for the flags
flag_gpu=0
flag_test=0
flag_local_notebook=0
flag_local_requirements=0

# Flag to check if an explicitly selected version is historical (older than latest).
flag_version_selected=0

# Let's parse the arguments
while getopts :hc:d:o:gn:r:t:p:x flag;do
    case $flag in 
        h)
            usage ;;
        c)
            config_path="$OPTARG" ;;
        d)
            data_path="$OPTARG" ;;
        o)
            result_path="$OPTARG" ;;
        g)
            if nvidia-smi &> /dev/null; then
                flag_gpu=1
            else
                echo ""
                echo "Sorry, there is no configured Nvidia graphic card on your device, the docker image will be created without GPU."
                echo ""
            fi ;;
        n)
            notebook_path="$OPTARG" ;;
        r)
            requirements_path="$OPTARG" ;;
        t)
            docker_tag="$OPTARG" ;;
        p)
            port_number="$OPTARG" ;;
        x)
            flag_test=1 ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "Try bash ./launch.sh -h for more information."
            # Close the terminal
            exit 1 ;;
    esac
done

# Check if test mode is active
if [ "$flag_test" -eq 1 ]; then
    echo 'Test mode is enabled.'
fi

if [ $flag_gui -eq 0 ]; then 
    # If GUI is not requested
    if [ "$flag_test" -eq 1 ]; then
        echo "GUI is not requested, proceeding with CLI."
    fi
else
    # If the GUI flag has been specified, run the function to show the GUI and read the arguments
    gui_arguments=$(wish "$BASEDIR/.tools/tcl_tools/main_gui.tcl" "$BASEDIR" "$OSTYPE")

    if [ -z "$gui_arguments" ]; then
        # No arguments were provided, this means that the GUI has been closed, so close the terminal
        exit 1
    fi

    IFS=$'\n' read -d '' -r -a strarr <<<"$gui_arguments"

    # The GUI uses a separate marker for uninstall so it cannot be mistaken for
    # the normal simple/advanced launch protocol.
    if [ "${strarr[0]}" = "__DL4ME_UNINSTALL__" ]; then
        clean_docker_images="${strarr[1]:-0}"
        /bin/bash "$BASEDIR/.tools/bash_tools/uninstall_dl4miceverywhere.sh" "$clean_docker_images"
        exit $?
    fi

    advanced_options=${strarr[0]}

    if [ $advanced_options -eq 0 ]; then
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"
        selectedFolder="${strarr[3]}"
        selectedNotebook="${strarr[4]}"
        flag_gpu="${strarr[5]}"
        selectedVersion="${strarr[6]}"
        tag_aux="${strarr[7]}"

        cache_gui "$data_path" "$result_path" "$selectedFolder" "$selectedNotebook" "" "" "" "$flag_gpu" "$selectedVersion" "$tag_aux" "$advanced_options"

        # A custom Docker tag takes precedence, but an empty GUI field is not
        # a tag override. Older-version selection must still be processed when
        # the custom-tag field is blank.
        if [ -n "$tag_aux" ] && [ "$tag_aux" != "-" ]; then
            docker_tag="$tag_aux"
        elif [ "$selectedVersion" != "-" ]; then
            versioned_docker_tag=$(/bin/bash "$BASEDIR/.tools/bash_tools/get_docker_tag.sh" "$selectedNotebook" "$selectedVersion")

            # The version list marks the current release with "(latest)". Only
            # genuinely older releases are historical/pull-only; explicitly
            # choosing the current (latest) release keeps normal build options.
            case "$selectedVersion" in
                *"(latest)") flag_version_selected=0 ;;
                *) flag_version_selected=1 ;;
            esac
        fi

        config_path="$BASEDIR/notebooks/$selectedFolder/$selectedNotebook/configuration.yaml"
    else
        data_path="${strarr[1]}"
        result_path="${strarr[2]}"

        config_path="${strarr[3]}"

        notebook_aux="${strarr[4]}"
        requirements_aux="${strarr[5]}"
        
        flag_gpu="${strarr[6]}"
        selectedVersion="${strarr[7]}"
        tag_aux="${strarr[8]}"

        cache_gui "$data_path" "$result_path" "" "" "$config_path" "$notebook_aux" "$requirements_aux" "$flag_gpu" "" "$tag_aux" "$advanced_options"

        if [ "$notebook_aux" != "-" ]; then
            notebook_path="$notebook_aux"
        fi
        if [ "$requirements_aux" != "-" ]; then
            requirements_path="$requirements_aux"
        fi
        if [ -n "$tag_aux" ] && [ "$tag_aux" != "-" ]; then
            docker_tag="$tag_aux"
        fi
    fi
fi

if [ -z "$config_path" ]; then 
    # If no configuration path has been specified, then exit with the error
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the configuration.yaml file has been specified."
    echo "If you are using the CLI, please make sure to use -c argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a default"
    echo "notebook or a local oath to a configuration."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # If a configuration path has been specified, check if it is valid
    if [[ -d "$config_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
        config_path="$config_path/configuration.yaml"
    elif [[ -f "$config_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the configuration folder: $config_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the configuration is not valid: $config_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ -z "$data_path" ]; then 
    # Exit with an error if no data path is specified
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the data folder has been specified."
    echo "If you are using the CLI, please make sure to use -d argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a path to the data folder."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # Validate the specified data path
    if [[ -d "$data_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Data path: $data_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the data folder is not valid: $data_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ -z "$result_path" ]; then 
    # Exit with an error if no result path is specified
    # Close the terminal
    echo ""
    echo "------------------------------------"
    echo "No path to the output folder has been specified."
    echo "If you are using the CLI, please make sure to use -o argument and give a value to it."
    echo "If you are using the GUI, please make sure to use that you have selected a path to the output folder."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1
else
    # Validate the specified result path
    if [[ -d "$result_path" ]]; then
        if [ "$flag_test" -eq 1 ]; then
            echo "Result path: $result_path"
        fi
    else
        # Close the terminal
        echo ""
        echo "------------------------------------"
        echo "The give path to the output folder is not valid: $result_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi 

if [ "$flag_test" -eq 1 ]; then
    # If the test flag is set, print whether the GPU flag has been set
    if [ "$flag_gpu" -eq 1 ]; then
        echo 'GPU usage is enabled.'
    else
        echo 'GPU usage is disabled.'
    fi
fi

# Read the variables from the yaml file
eval $(get_yaml_args_from_file "$config_path")

# Check the parsed variables
check_parsed_argument notebook_url
check_parsed_argument requirements_url
check_parsed_argument cuda_version
check_parsed_argument cudnn_version
check_parsed_argument ubuntu_version
check_parsed_argument python_version
check_parsed_argument notebook_version
rename_parsed_argument description # Not required to be present and therefore the cheking is skipped
rename_parsed_argument sections_to_remove # Not required to be present and therefore the cheking is skipped
rename_parsed_argument dl4miceverywhere_version # Not required to be present and therefore the cheking is skipped
rename_parsed_argument docker_hub_image # Not required to be present and therefore the cheking is skipped

# Remote GitHub notebook build inputs are deterministic only when the immutable
# commit is encoded directly in the URL. Bundled dependency inputs are local.
if [[ "$notebook_url" == https://raw.githubusercontent.com/* ]] && \
   ! [[ "$notebook_url" =~ ^https://raw\.githubusercontent\.com/[^/]+/[^/]+/[0-9a-fA-F]{40}/.+$ ]]; then
    echo "Configuration reproducibility check failed." >&2
    echo "GitHub notebook URLs must contain a full 40-character commit SHA:" >&2
    echo "  $notebook_url" >&2
    exit 1
fi

# Check if the notebook path is missing (SIMPLE USECASE) 
if [ -z "$notebook_path" ]; then
    # Then the URL from the configuration file is used as notebook path
    notebook_path="${notebook_url}"

    # For the auxiliar docker tag, check if there is a notebook version
    if [ ! -z "$versioned_docker_tag" ]; then
        # If so, the corresponding versioned docker tag will be used as the auxiliar one
        aux_docker_tag="${versioned_docker_tag}"
    else
        # Otherwise, if the version is missing, 
        # check if on advanced mode a docker hub image name has been selected
        if [ ! -z "$docker_hub_image" ]; then
            # If so, assign it as auxiliar docker tag
            aux_docker_tag="${docker_hub_image}"
        else
            # Otherwise, assing it from the notebook name 
            aux_docker_tag="$(basename "$notebook_path" .ipynb)"
        fi
    fi

    if [ "$flag_test" -eq 1 ]; then
        echo "Since no notebook was specified, the notebook URL from 'configuration.yaml' will be used."
    fi
else
    # Otherwise check if the path is valid
    # If there is no versioned tag
    if [ -z "$versioned_docker_tag" ]; then
        # For the docker's tag if not specified
        if [ -z "$docker_hub_image" ]; then
            aux_docker_tag="$(basename "$notebook_path" .ipynb)"
        else
            aux_docker_tag="${docker_hub_image}"
        fi
    else
        aux_docker_tag="${versioned_docker_tag}"
    fi

    if [ -f "$notebook_path" ]; then
    
        if [ "$flag_test" -eq 1 ]; then
            echo "Path to the notebook: $notebook_path"
        fi
        
        # If the notebook path is not valid, activate its flag for future processing
        flag_local_notebook=1
    else
        echo ""
        echo "------------------------------------"
        echo "The give path to the notebook.ipynb is not valid: $notebook_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi

requirements_override=0
requirements_input_path=""

if [ -z "$requirements_path" ]; then
    # requirements_url is a real source/provenance URL. Bundled notebooks also
    # carry a committed sibling requirements.txt, which is the authoritative
    # deterministic input used to generate requirements.lock.txt.
    requirements_path="${requirements_url}"
    bundled_requirements_path="$(dirname "$config_path")/requirements.txt"
    if [ -f "$bundled_requirements_path" ]; then
        requirements_input_path="$bundled_requirements_path"
        flag_local_requirements=1
        if [ "$flag_test" -eq 1 ]; then
            echo "Requirements source URL: $requirements_url"
            echo "Using bundled dependency input: $requirements_input_path"
        fi
    else
        # Custom/legacy configurations without a bundled mirror may resolve the
        # URL declared in configuration.yaml when a local build is required.
        requirements_input_path="$requirements_url"
        flag_local_requirements=0
        if [ "$flag_test" -eq 1 ]; then
            echo "Using dependency input declared by configuration.yaml: $requirements_input_path"
        fi
    fi
else
    requirements_override=1
    # Advanced/CLI mode explicitly supplied a local requirements file.
    if [ -f "$requirements_path" ]; then
        requirements_input_path="$requirements_path"
        if [ "$flag_test" -eq 1 ]; then 
            echo "Path to the requirements file: $requirements_path"
        fi
        flag_local_requirements=1
    else
        echo ""
        echo "------------------------------------"
        echo "The given path to the requirements input is not valid: $requirements_path"
        echo "Please, check that this path is correct and exists."
        read -p "Press enter to close the terminal."
        echo "------------------------------------" 
        exit 1
    fi
fi

if [ -z "$docker_tag" ]; then
    # If no tag has been specified for the docker image, then the default tag will be used (the name of the notebook)
    docker_tag=$aux_docker_tag
    if [ "$flag_test" -eq 1 ]; then 
        echo "No tag has been specified for the docker image, therefore the default tag $docker_tag will be used."
    fi

    # If no version 
    if [ -z "$docker_hub_image" ] && [ -z "$versioned_docker_tag" ]; then
        # Get the notebook type of the configuration file
        if [[ "$config_path" = *'ZeroCostDL4Mic_notebooks'* ]]; then
            notebook_type='z'
        elif [[ "$config_path" = *'External_notebooks'* ]]; then
            notebook_type='e'
        elif [[ "$config_path" = *'Bespoke_notebooks'* ]]; then
            notebook_type='b'
        else
            # Is a custom configuration that is not in any of these notebook types
            # therefore the notebook type will be 'n'
            notebook_type='n'
        fi

        # In case the configuration file does not have a docker_hub_image attribute
        docker_tag=$(echo $docker_tag | tr '[:upper:]' '[:lower:]')
        docker_tag=henriqueslab/dl4miceverywhere:$docker_tag
        if [ -z "$dl4miceverywhere_version" ]; then
            docker_tag=$docker_tag-$notebook_type$notebook_version-d___
        else
            docker_tag=$docker_tag-$notebook_type$notebook_version-d$dl4miceverywhere_version
        fi
    else
        if [ -z "$versioned_docker_tag" ]; then
            # In case there is no versioned_docker_tag attribute, that meens that there is a docker_hub_image
            # In case the configuration file already has a docker_hub_image attribute
            docker_tag=henriqueslab/dl4miceverywhere:$docker_hub_image
        else
            # Otherwise, it means that versioned_docker_tag was provided and will be used
            docker_tag=henriqueslab/dl4miceverywhere:$versioned_docker_tag
        fi
    fi

    # Check if GPU has been requested and add it to the tag if necessary
    if [ "$flag_gpu" -eq 1 ]; then
        docker_tag=$docker_tag-gpu
    fi
else
    echo "The docker tag $docker_tag has been selected."
    echo ""
    echo "################################"
    echo ""
fi


selected_dockerfile=$(select_dockerfile "$flag_gpu" "$python_version")

# Set the docker's tag
if [ "$flag_test" -eq 1 ]; then
    echo ""
    echo "ubuntu_version: $ubuntu_version"
    echo "cuda_version: $cuda_version"
    echo "cudnn_version: $cudnn_version"
    echo "python_version: $python_version"
    echo "notebook_path: $notebook_path"
    echo "requirements_path: $requirements_path"
    echo "sections_to_remove: $sections_to_remove"
    echo "notebook_version: $notebook_version"
    echo "description: $description"
    echo "docker_tag: $docker_tag"
    echo "selected_dockerfile: $selected_dockerfile"
    echo ""
fi

notebook_name="$(basename "$notebook_path")"

# Local files, if included, need to be recreated in the repository root (the Docker build context),
# then they will be deleted
if [ "$flag_local_notebook" -eq 1 ]; then
    cp "$notebook_path" "$BASEDIR/notebook.ipynb"
    notebook_path=./notebook.ipynb
fi


# Check if there is the errata in ~/.docker/config.json where credsStore should be credStore
if grep -q credsStore ~/.docker/config.json; then
    # Apparently, on MaxOS, it returns: 
    #   ERROR: failed to solve: error getting credentials - err: exit status 1, out: “ 
    # It can be solved by changing this argument in the configuration file (working also on Linux with this change).
    perl -pi -e "s/credsStore/credStore/g" ~/.docker/config.json 
fi

# Execute the pre building tests
/bin/bash "$BASEDIR/.tools/bash_tools/pre_build_test.sh" "$docker_tag" || exit 1

###
# Get what is the containerisation system that will be used
if [ ! -f "$BASEDIR/../.cache/.cache_preferences" ]; then
    # It shouldn't enter here, because at this point the .cache_preferences file
    # should be created. But just in case, Docker is the default containerisation sysyem.
    containerisation="Docker"
else
   containerisation=$(awk -F' : ' '$1 == "containerisation" {print $2}' "$BASEDIR/../.cache/.cache_preferences")
fi
###

# Decide whether to reuse, pull, or build the image.
# Historical versions are deliberately pull/reuse-only: building them with the
# current configuration would create a new image with an old-looking tag.
flag_build=0

historical_image_available_for_arch() {
    local image_tag="$1"
    local local_arch
    local arch_count

    if ! docker manifest inspect "$image_tag" >/dev/null 2>&1; then
        return 1
    fi

    local_arch=$(uname -m)
    if [ "$local_arch" = "x86_64" ]; then
        local_arch="amd64"
    elif [ "$local_arch" = "aarch64" ]; then
        local_arch="arm64"
    fi

    arch_count=$(docker manifest inspect "$image_tag" -v 2>/dev/null \
        | grep 'architecture' \
        | grep -c "$local_arch")
    [ "$arch_count" -gt 0 ]
}

historical_image_unavailable() {
    local error_message="The selected older version is not available on Docker Hub for this computer. Please choose another version or use the current version."
    if [ "$flag_gui" -eq 1 ]; then
        wish "$BASEDIR/.tools/tcl_tools/oneline_done_gui.tcl" \
            "Older image not available" "$error_message"
    else
        echo "$error_message"
    fi
}

# Explicitly selected historical versions can never enter the local-build path.
if [ "$flag_version_selected" -eq 1 ] && [[ "$containerisation" == "Docker"* ]]; then
    historical_download_requested=0

    if docker image inspect "$docker_tag" >/dev/null 2>&1; then
        # The exact historical image already exists locally. Offer reuse or a
        # fresh download of the published image, but never offer Build.
        if [ "$flag_gui" -eq 1 ]; then
            flag_build=$(wish "$BASEDIR/.tools/tcl_tools/historical_local_img_gui.tcl" "$docker_tag")
        else
            echo "The selected older image already exists locally:"
            echo "  $docker_tag"
            echo "Older versions cannot be rebuilt from the current configuration."
            select action in "Use existing image" "Download from Docker Hub" "Cancel"; do
                case "$action" in
                    "Use existing image") flag_build=1; break ;;
                    "Download from Docker Hub") flag_build=3; break ;;
                    "Cancel") flag_build=0; break ;;
                esac
            done
        fi

        if [ -z "$flag_build" ] || [ "$flag_build" -eq 0 ]; then
            echo "Older-version launch cancelled."
            exit 0
        fi

        if [ "$flag_build" -eq 3 ]; then
            historical_download_requested=1
        fi
    else
        # There is no local copy. For a historical version the only valid
        # action is to download the published image from Docker Hub.
        if ! historical_image_available_for_arch "$docker_tag"; then
            historical_image_unavailable
            exit 1
        fi

        if [ "$flag_gui" -eq 1 ]; then
            flag_build=$(wish "$BASEDIR/.tools/tcl_tools/historical_download_gui.tcl" "$docker_tag")
        else
            echo "For older versions, only downloading from Docker Hub is available."
            echo "Selected image: $docker_tag"
            read -r -p "Continue with the download? [y/N]: " historical_answer
            case "$historical_answer" in
                y|Y|yes|YES|Yes) flag_build=3 ;;
                *) flag_build=0 ;;
            esac
        fi

        if [ -z "$flag_build" ] || [ "$flag_build" -eq 0 ]; then
            echo "Older-version download cancelled."
            exit 0
        fi

        historical_download_requested=1
    fi

    # If the user requested a fresh download for a local historical image,
    # validate Docker Hub availability and architecture before pulling.
    if [ "$historical_download_requested" -eq 1 ]; then
        if ! historical_image_available_for_arch "$docker_tag"; then
            historical_image_unavailable
            exit 1
        fi
        flag_build=3
    fi
else
    # Current/default versions keep the existing build/pull/reuse choices.
    # In testing mode, force a local build only for the current configuration.
    if [ "$flag_test" -eq 1 ]; then
        flag_build=2
    elif [[ "$containerisation" == "Docker"* ]]; then
        # Check if there is a docker image with that tag locally.
        if docker image inspect "$docker_tag" >/dev/null 2>&1; then
            if [ "$flag_gui" -eq 1 ]; then
                flag_build=$(wish "$BASEDIR/.tools/tcl_tools/local_img_gui.tcl" "$OSTYPE")
            else
                echo "Image exists locally. Do you want to build and replace the existing one?"
                select yn in "Yes" "No"; do
                    case "$yn" in
                        Yes) flag_build=2; break ;;
                        No) flag_build=1; break ;;
                    esac
                done
            fi
        fi

        if [ -z "$flag_build" ]; then
            echo ""
            echo "------------------------------------"
            echo "You should have chosen an option."
            read -r -p "Press enter to close the terminal."
            echo "------------------------------------"
            exit 1
        fi

        # If the local image is not being reused, see whether Docker Hub has it.
        if [ "$flag_build" -ne 1 ]; then
            if docker manifest inspect "$docker_tag" >/dev/null 2>&1; then
                local_arch=$(uname -m)
                if [ "$local_arch" = "x86_64" ]; then
                    local_arch="amd64"
                elif [ "$local_arch" = "aarch64" ]; then
                    local_arch="arm64"
                fi

                arch_count=$(docker manifest inspect "$docker_tag" -v 2>/dev/null \
                    | grep 'architecture' \
                    | grep -c "$local_arch")

                if [ "$arch_count" -gt 0 ]; then
                    if [ "$flag_gui" -eq 1 ]; then
                        flag_build=$(wish "$BASEDIR/.tools/tcl_tools/hub_img_gui.tcl" "$OSTYPE")
                    else
                        echo "The image $docker_tag is already available on Docker Hub. Do you prefer to pull it (faster option) instead of building it?"
                        select yn in "Yes" "No"; do
                            case "$yn" in
                                Yes) flag_build=3; break ;;
                                No) flag_build=2; break ;;
                            esac
                        done
                    fi

                    if [ -z "$flag_build" ]; then
                        echo ""
                        echo "------------------------------------"
                        echo "You should have chosen an option."
                        read -r -p "Press enter to close the terminal."
                        echo "------------------------------------"
                        exit 1
                    fi
                else
                    # No compatible published image: current versions may still
                    # be built locally.
                    flag_build=2
                fi
            else
                # No published image: current versions may still be built locally.
                flag_build=2
            fi
        fi
    fi
fi

# Safety invariant: an explicitly selected historical version must never be
# built from the current configuration, even if future decision logic changes.
if [ "$flag_version_selected" -eq 1 ] && [ "$flag_build" -eq 2 ]; then
    echo ""
    echo "------------------------------------"
    echo "Older Docker image versions cannot be built from the current configuration."
    echo "Please use an existing local copy or download the published image from Docker Hub."
    echo "------------------------------------"
    exit 1
fi

if [ "$flag_build" -eq 3 ]; then
    echo "The image will be pulled from Docker Hub."
elif [ "$flag_build" -eq 2 ]; then
    echo "The image will be built locally."
elif [ "$flag_build" -eq 1 ]; then
    echo "A local version of the image will be used."
else
    echo "SOMETHING WENT WRONG :("
fi

# Deterministic dependency locks are needed only when an image is actually built.
# Pulling or reusing an existing image never resolves or updates Python dependencies.
requirements_lock_path=""
requirements_lock_context_path=""
converter_lock_path="$BASEDIR/docker/converter-requirements.lock.txt"
build_input_dir="$BASEDIR/.tools/docker_build_inputs"

cleanup_lock_build_input() {
    if [ -n "$requirements_lock_context_path" ]; then
        rm -f "$BASEDIR/$requirements_lock_context_path"
    fi
    rmdir "$build_input_dir" 2>/dev/null || true
}

if [ "$flag_build" -eq 2 ]; then
    if [ ! -f "$selected_dockerfile" ]; then
        echo ""
        echo "------------------------------------"
        echo "The selected Dockerfile does not exist: $selected_dockerfile"
        echo "Please make sure the repository contains the split modern/legacy Dockerfiles under the docker/ folder."
        read -r -p "Press enter to close the terminal."
        echo "------------------------------------"
        exit 1
    fi

    echo "Checking deterministic Python dependency lock..."

    # Lock validation itself only needs Python. The venv/pinned resolver is
    # required only when a missing or stale lock actually needs regeneration.
    if ! command -v python3 >/dev/null 2>&1; then
        /bin/bash "$BASEDIR/.tools/bash_tools/requirements_installation/python3_lock_tools.sh" || exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python 3 is required to maintain deterministic dependency locks." >&2
        exit 1
    fi

    if [ "$requirements_override" -eq 1 ]; then
        requirements_lock_path="$(dirname "$(readlink -f "$requirements_input_path")")/requirements.lock.txt"
        notebook_lock_args=(
            --config "$config_path"
            --source "$requirements_input_path"
            --python-version "$python_version"
            --lock "$requirements_lock_path"
            --repo-root "$BASEDIR"
        )
    else
        requirements_lock_path="$(dirname "$(readlink -f "$config_path")")/requirements.lock.txt"
        notebook_lock_args=(--config "$config_path" --repo-root "$BASEDIR")
    fi

    converter_lock_args=(
        --source "$BASEDIR/docker/converter-requirements.txt"
        --python-version "3.9"
        --lock "$converter_lock_path"
        --profile none
        --repo-root "$BASEDIR"
    )

    lock_needs_resolver=0
    python3 "$BASEDIR/.tools/python_tools/requirements_lock.py" check "${notebook_lock_args[@]}" --quiet >/dev/null 2>&1 || lock_needs_resolver=1
    python3 "$BASEDIR/.tools/python_tools/requirements_lock.py" check "${converter_lock_args[@]}" --quiet >/dev/null 2>&1 || lock_needs_resolver=1

    if [ "$lock_needs_resolver" -eq 1 ]; then
        lock_venv_test_dir="$(mktemp -d 2>/dev/null || true)"
        lock_venv_ready=0
        if [ -n "$lock_venv_test_dir" ] && python3 -m venv "$lock_venv_test_dir/test" >/dev/null 2>&1; then
            lock_venv_ready=1
        fi
        [ -n "$lock_venv_test_dir" ] && rm -rf "$lock_venv_test_dir"
        if [ "$lock_venv_ready" -ne 1 ]; then
            /bin/bash "$BASEDIR/.tools/bash_tools/requirements_installation/python3_lock_tools.sh" || exit 1
        fi
    fi

    python3 "$BASEDIR/.tools/python_tools/requirements_lock.py" ensure "${notebook_lock_args[@]}" || exit 1

    # The notebook converter has its own small deterministic lock and does not
    # inherit the notebook runtime profile.
    python3 "$BASEDIR/.tools/python_tools/requirements_lock.py" ensure "${converter_lock_args[@]}" || exit 1

    if [ ! -f "$requirements_lock_path" ]; then
        echo "Dependency lock was not created: $requirements_lock_path" >&2
        exit 1
    fi

    # Docker COPY sources must live inside the build context. Stage only the
    # generated lock; the human-facing requirements input is never installed.
    mkdir -p "$build_input_dir"
    requirements_lock_context_path=".tools/docker_build_inputs/requirements-$$.lock.txt"
    cp "$requirements_lock_path" "$BASEDIR/$requirements_lock_context_path" || exit 1
    trap cleanup_lock_build_input EXIT
fi

# If flag_build is 3 the pull the docker image from docker hub
if [ "$flag_build" -eq 3 ]; then
    # Pull the docker image
    docker pull "$docker_tag"
    DOCKER_OUT=$? # Gets if the docker image has been pulled
else
    # Build the docker image without GUI
    if [ "$flag_build" -eq 2 ]; then
        echo "To build the docker image, you need to provide root access by entering your password."
        echo "Otherwise, you can choose the option of getting the image from Docker Hub or follow"
        echo "the steps in our documentation."
        if [ "$flag_gpu" -eq 1 ]; then
            sudo docker build --file "$selected_dockerfile" -t "$docker_tag" \
                --label "org.dl4miceverywhere.managed=true" \
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg CUDA_VERSION="${cuda_version}" \
                --build-arg CUDNN_VERSION="${cudnn_version}" \
                --build-arg GPU_FLAG="${flag_gpu}" \
                --build-arg PYTHON_VERSION="${python_version}" \
                --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
                --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
                --build-arg PATH_TO_REQUIREMENTS_LOCK="${requirements_lock_context_path}" \
                --build-arg NOTEBOOK_NAME="${notebook_name}" \
                --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" \
                "$BASEDIR"
        else
            sudo docker build --file "$selected_dockerfile" -t "$docker_tag" \
                --label "org.dl4miceverywhere.managed=true" \
                --build-arg UBUNTU_VERSION="${ubuntu_version}" \
                --build-arg CUDA_VERSION="${cuda_version}" \
                --build-arg CUDNN_VERSION="${cudnn_version}" \
                --build-arg GPU_FLAG="${flag_gpu}" \
                --build-arg PYTHON_VERSION="${python_version}" \
                --build-arg PATH_TO_NOTEBOOK="${notebook_path}" \
                --build-arg PATH_TO_REQUIREMENTS="${requirements_path}" \
                --build-arg PATH_TO_REQUIREMENTS_LOCK="${requirements_lock_context_path}" \
                --build-arg NOTEBOOK_NAME="${notebook_name}" \
                --build-arg SECTIONS_TO_REMOVE="${sections_to_remove}" \
                "$BASEDIR"
        fi

        DOCKER_OUT=$? # Gets if the docker image has been built
        cleanup_lock_build_input
        trap - EXIT
    else
        if [ "$flag_build" -eq 1 ]; then
            DOCKER_OUT=0 # In case that is already built, it is good to run
        else
            # build flag is still 0, an error ocurred
            echo ""
            echo "------------------------------------"
            echo "Error looking for existing docker image with the given tag:"
            echo "$docker_tag"
            read -p "Press enter to close the terminal."
            echo "------------------------------------" 
            # Close the terminal
            exit 1
        fi
    fi
fi

# Do not report success or run post-build checks if the pull/build failed.
if [ "$DOCKER_OUT" -ne 0 ]; then
    echo ""
    echo "------------------------------------"
    echo "Docker image build/pull failed."
    echo "Please review the Docker output above for details."
    echo "------------------------------------"
    exit "$DOCKER_OUT"
fi

echo "Docker image is ready."

# Execute the post building tests against the image that will be launched.
/bin/bash "$BASEDIR/.tools/bash_tools/post_build_test.sh" "$docker_tag" "$flag_gpu" || exit 1

sleep 3

# Local files, if included, need to be removed to avoid the overcrowding the folder
if [ "$flag_local_notebook" -eq 1 ]; then
   rm "$BASEDIR/notebook.ipynb"
fi


if [ "$DOCKER_OUT" -eq 0 ] && [ "$flag_build" -ne 1 ]; then
    track_managed_docker_image "$docker_tag"
fi

# If it has been built, run the docker
if [ "$DOCKER_OUT" -eq 0 ]; then
    if [ $flag_test -eq 1 ]; then
        # In case ,testing is done, only building is required, exit before running
        exit 0
    fi

    # Choose an initial port
    if [ -z "$port_number" ]; then
        # In case user does not provide a port number, use the default 8888 port
        port=8888
    else
        # Else, use the port provided by the user
        port="$port_number"
    fi

    # Check if selected port is available if not try next one until finding a usable port. 
    if [[ "$OSTYPE" == "linux-gnu"* && "$(systemd-detect-virt)" == "wsl"* ]]; then        
        # Linux inside the Windows Subsystem for Linux needs to look differently to the ports
        while ( netstat -a | grep :$port &> /dev/null )
        do
            echo WARNING: Port $port is already allocated.
            port=$((port+1))
            if [ $port -gt 9000 ]; then
                # We want the port to be between 8000 and 9000
                port=8000
            sleep 1
            fi
        done
    else
        while ( lsof -i:$port &> /dev/null )
        do
            echo WARNING: Port $port is already allocated.
            port=$((port+1))
            if [ $port -gt 9000 ]; then
                # We want the port to be between 8000 and 9000
                port=8000
            sleep 1
            fi
        done
    fi
    echo SUCCESS: Port $port will be used.

    # Based on the openssl command and the base64 encoding, a 50 characters token is generated
    notebook_token=$(openssl rand -base64 50 | tr -dc 'a-zA-Z0-9')

    echo ""
    echo "################################################################################################################################"
    echo ""
    echo "   The generated token for the notebook is: $notebook_token"
    echo ""
    echo "################################################################################################################################"
    echo ""

    # Launch a subprocess to open the browser with the port in 10 seconds
    /bin/bash "$BASEDIR/.tools/bash_tools/open_browser.sh" 10 "http://localhost:$port/lab/tree/$notebook_name/?token=$notebook_token" &

    # Define the command that will be run when the docker image is launched
    docker_command="jupyter lab --ip='0.0.0.0' --port=$port --no-browser --allow-root --NotebookApp.token=$notebook_token; cp /home/docker_info.txt /home/results/docker_info.txt; cp /home/$notebook_name /home/results/$notebook_name;" 

    if [ "$flag_gpu" -eq 1 ]; then
        # Run the docker image activating the GPU, allowing the port connection for the notebook and the volume with the data 
        docker run -it --label org.dl4miceverywhere.managed=true --gpus all -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" --shm-size=256m "$docker_tag"  /bin/bash -c "$docker_command"
        echo -e "The command used to run this container has been:\n\tdocker run -it --label org.dl4miceverywhere.managed=true --gpus all -p $port:$port -v \"$data_path:/home/data\" -v \"$result_path:/home/results\" --shm-size=256m \"$docker_tag\"  /bin/bash -c \"$docker_command\"" >> "$result_path/docker_info.txt"
    else
        # Run the docker image without activating the GPU
        docker run -it --label org.dl4miceverywhere.managed=true -p $port:$port -v "$data_path:/home/data" -v "$result_path:/home/results" --shm-size=256m "$docker_tag"  /bin/bash -c "$docker_command"
        echo -e "The command used to run this container has been:\n\tdocker run -it --label org.dl4miceverywhere.managed=true -p $port:$port -v \"$data_path:/home/data\" -v \"$result_path:/home/results\" --shm-size=256m \"$docker_tag\"  /bin/bash -c \"$docker_command\"" >> "$result_path/docker_info.txt"
    fi


    # Read the variables from the yaml file
    echo -e "Used docker tag has been:\n\t$docker_tag" >> "$result_path/docker_info.txt"

    eval $(get_yaml_args_from_file "$BASEDIR/construct.yaml" "contruct_info_")
    echo -e "Used DL4MicEverywhere version has been:\n\t$contruct_info_version" >> "$result_path/docker_info.txt"

else
    echo ""
    echo "------------------------------------"
    echo "Error during the building of the docker image. Please check the logs."
    read -p "Press enter to close the terminal."
    echo "------------------------------------" 
    exit 1 
fi

# A user stopping the interactive notebook session is a normal completion.
echo "------------------------------------"
echo "DL4MicEverywhere session finished."
echo "------------------------------------"
read -p "Press enter to close the terminal."

exit 0
