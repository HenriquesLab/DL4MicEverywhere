#!/bin/bash

# Targeted DL4MicEverywhere uninstaller.
# $1: 1 to remove DL4MicEverywhere Docker resources, 0 otherwise.
#
# Exit code 42 is reserved for Windows/WSL. In that case Docker cleanup is
# completed here, but the Windows launcher removes the application folder only
# after WSL has returned, avoiding deletion of a directory still in use by cmd.

set -u

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
TARGET_DIR=$(readlink -f "$SCRIPT_DIR/../..")
CLEAN_DOCKER="${1:-0}"
WINDOWS_DELETE_EXIT=42

show_error() {
    local message="$1"
    echo ""
    echo "------------------------------------"
    echo "DL4MicEverywhere could not be uninstalled."
    echo "$message"
    echo "Nothing in the DL4MicEverywhere application folder was removed."
    echo "------------------------------------"

    if command -v wish >/dev/null 2>&1 && [ -f "$TARGET_DIR/.tools/tcl_tools/menubar/uninstall.tcl" ]; then
        wish "$TARGET_DIR/.tools/tcl_tools/menubar/uninstall.tcl" \
            --error \
            "$message Nothing in the DL4MicEverywhere application folder was removed." \
            >/dev/null 2>&1 || true
    fi
}

# Refuse to recurse into an unexpected directory. This makes an accidental bad
# BASEDIR much safer than an unconditional rm -rf.
if [ -z "$TARGET_DIR" ] || [ "$TARGET_DIR" = "/" ] || [ "$TARGET_DIR" = "$HOME" ]; then
    show_error "The application folder could not be identified safely."
    exit 1
fi

if [ ! -f "$TARGET_DIR/Linux_launch.sh" ] || \
   [ ! -f "$TARGET_DIR/construct.yaml" ] || \
   [ ! -d "$TARGET_DIR/.tools/tcl_tools" ]; then
    show_error "The selected folder does not look like a DL4MicEverywhere installation."
    exit 1
fi

clean_docker_resources() {
    local refs_file ids_file containers_file tracked_file failures
    refs_file=$(mktemp)
    ids_file=$(mktemp)
    containers_file=$(mktemp)
    tracked_file="$TARGET_DIR/.tools/.cache/.managed_docker_images"
    failures=0

    cleanup_temp_files() {
        rm -f "$refs_file" "$ids_file" "$containers_file"
    }

    if ! command -v docker >/dev/null 2>&1; then
        cleanup_temp_files
        show_error "Docker is not available, so the requested Docker-image cleanup could not be completed. Start Docker and try again, or uncheck the Docker cleanup option."
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        cleanup_temp_files
        show_error "Docker is installed but is not currently available, so the requested Docker-image cleanup could not be completed. Start Docker and try again, or uncheck the Docker cleanup option."
        return 1
    fi

    # All normal DL4MicEverywhere pull/build tags live under this repository.
    docker image ls --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
        | grep '^henriqueslab/dl4miceverywhere:' >> "$refs_file" || true

    # Locally-built custom-tag images from newer DL4MicEverywhere versions are
    # also labelled, so they can be removed without touching unrelated images.
    docker image ls --filter 'label=org.dl4miceverywhere.managed=true' \
        --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
        | grep -v '^<none>:' >> "$refs_file" || true

    docker image ls -q --filter 'label=org.dl4miceverywhere.managed=true' \
        2>/dev/null >> "$ids_file" || true

    # Custom image tags are recorded with the image ID at the moment this
    # launcher builds/pulls them. Only remove the tag if it still points to the
    # same image, preventing deletion of an unrelated image that later reused
    # the same custom tag.
    if [ -f "$tracked_file" ]; then
        while IFS='|' read -r recorded_id recorded_ref; do
            [ -n "$recorded_id" ] || continue
            [ -n "$recorded_ref" ] || continue

            current_id=$(docker image inspect --format '{{.Id}}' "$recorded_ref" 2>/dev/null || true)
            if [ "$current_id" = "$recorded_id" ]; then
                echo "$recorded_ref" >> "$refs_file"
                echo "$recorded_id" >> "$ids_file"
            fi
        done < "$tracked_file"
    fi

    sort -u "$refs_file" -o "$refs_file"
    sort -u "$ids_file" -o "$ids_file"

    # Remove containers that DL4MicEverywhere created with the management label.
    docker ps -aq --filter 'label=org.dl4miceverywhere.managed=true' \
        2>/dev/null >> "$containers_file" || true

    # Older releases did not label containers. Find containers whose image is
    # one of the DL4MicEverywhere images selected above.
    while IFS= read -r image_ref; do
        [ -n "$image_ref" ] || continue
        docker ps -aq --filter "ancestor=$image_ref" 2>/dev/null \
            >> "$containers_file" || true
    done < "$refs_file"

    sort -u "$containers_file" -o "$containers_file"

    if [ -s "$containers_file" ]; then
        while IFS= read -r container_id; do
            [ -n "$container_id" ] || continue
            if ! docker rm -f "$container_id" >/dev/null 2>&1; then
                failures=1
            fi
        done < "$containers_file"
    fi

    # Remove named references first, then labelled/tracked dangling IDs.
    while IFS= read -r image_ref; do
        [ -n "$image_ref" ] || continue
        if docker image inspect "$image_ref" >/dev/null 2>&1; then
            if ! docker image rm -f "$image_ref" >/dev/null 2>&1; then
                failures=1
            fi
        fi
    done < "$refs_file"

    while IFS= read -r image_id; do
        [ -n "$image_id" ] || continue
        if docker image inspect "$image_id" >/dev/null 2>&1; then
            if ! docker image rm -f "$image_id" >/dev/null 2>&1; then
                failures=1
            fi
        fi
    done < "$ids_file"

    # Verify that the project namespace and management label are gone. If not,
    # keep the application folder so the user can retry rather than leaving a
    # half-completed "clean" uninstall.
    if docker image ls --format '{{.Repository}}' 2>/dev/null \
        | grep -qx 'henriqueslab/dl4miceverywhere'; then
        failures=1
    fi

    if [ -n "$(docker image ls -q --filter 'label=org.dl4miceverywhere.managed=true' 2>/dev/null)" ]; then
        failures=1
    fi

    cleanup_temp_files

    if [ "$failures" -ne 0 ]; then
        show_error "One or more DL4MicEverywhere Docker resources could not be removed. The application was kept in place so you can retry safely."
        return 1
    fi

    return 0
}

if [ "$CLEAN_DOCKER" = "1" ]; then
    clean_docker_resources || exit 1
fi

# Remove the Linux desktop shortcut created by .tools/create_desktop.sh.
if command -v xdg-user-dir >/dev/null 2>&1; then
    DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || true)
    if [ -n "$DESKTOP_DIR" ]; then
        rm -f "$DESKTOP_DIR/DL4MicEverywhere.desktop" 2>/dev/null || true
    fi
fi

# When Windows_launch.bat starts WSL it sets an explicit marker. Let the batch
# launcher change out of the Windows application directory and delete it only
# after WSL exits. A user who launches Linux_launch.sh directly inside WSL does
# not have this marker and can use the normal Unix deletion path below.
if [ "${DL4ME_WINDOWS_WRAPPER:-0}" = "1" ] && \
   { grep -qi microsoft /proc/version 2>/dev/null || \
     [ "$(systemd-detect-virt 2>/dev/null || true)" = "wsl" ]; }; then
    exit "$WINDOWS_DELETE_EXIT"
fi

# Linux/macOS: leave the installation directory before removing it so no shell
# process keeps it as its current working directory.
cd /
rm -rf -- "$TARGET_DIR"
