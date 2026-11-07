#!/bin/bash

# Portable path helpers for Bash on Linux and macOS.
# macOS ships BSD readlink, which does not implement GNU `readlink -f`.
# These helpers resolve existing symlinks with plain `readlink` and normalize
# the containing directory with `pwd -P`, both available on stock macOS.

dl4me_realpath() {
    local input_path="$1"
    local resolved link target_dir target_base hops

    if [ -z "$input_path" ]; then
        return 1
    fi

    case "$input_path" in
        /*) resolved="$input_path" ;;
        *) resolved="$PWD/$input_path" ;;
    esac

    hops=0
    while [ -L "$resolved" ]; do
        hops=$((hops + 1))
        if [ "$hops" -gt 40 ]; then
            echo "Too many symbolic links while resolving: $input_path" >&2
            return 1
        fi

        link=$(readlink "$resolved") || return 1
        case "$link" in
            /*) resolved="$link" ;;
            *) resolved="$(dirname "$resolved")/$link" ;;
        esac
    done

    if [ -d "$resolved" ]; then
        (cd -P "$resolved" 2>/dev/null && pwd -P)
        return $?
    fi

    target_dir=$(dirname "$resolved")
    target_base=$(basename "$resolved")
    target_dir=$(cd -P "$target_dir" 2>/dev/null && pwd -P) || return 1
    printf '%s/%s\n' "$target_dir" "$target_base"
}

dl4me_script_dir() {
    local resolved_script
    resolved_script=$(dl4me_realpath "$1") || return 1
    dirname "$resolved_script"
}
