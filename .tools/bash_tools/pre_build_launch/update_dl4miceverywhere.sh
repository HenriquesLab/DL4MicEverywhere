#!/bin/bash

BASEDIR=$(dirname "$(readlink -f "$0")")
REPO_ROOT=$(readlink -f "$BASEDIR/../../..")
source "$BASEDIR/../launcher_status.sh"

# Git 2.35+ rejects repositories whose filesystem ownership does not match the
# current Linux UID. Windows checkouts mounted through WSL (/mnt/c/...) can
# legitimately trigger that protection even though this launcher is operating
# on its own checkout. Scope the exception to this exact checkout and to each
# individual Git command; never change the user's global Git configuration.
repo_git() {
    git -c safe.directory="$REPO_ROOT" -C "$REPO_ROOT" "$@"
}

already_asked="${1:-0}"
flag_gui="${2:-0}"

show_notice() {
    local title="$1"
    local message="$2"
    if [ "$flag_gui" -eq 1 ] && command -v wish >/dev/null 2>&1; then
        wish "$BASEDIR/../../tcl_tools/oneline_done_gui.tcl" "$title" "$message" || true
    else
        echo ""
        echo "------------------------------------"
        echo "$message"
        echo "------------------------------------"
    fi
}

show_check_unavailable() {
    local message="$1"
    if [ "$already_asked" = "1" ]; then
        show_notice "Update check unavailable" "$message"
    else
        echo "WARNING: $message" >&2
        echo "DL4MicEverywhere will continue using the current installation." >&2
    fi
}

if [ -f "$BASEDIR/../../.cache/.cache_preferences" ]; then
    update=$(awk -F' : ' '$1 == "update" {print $2}' "$BASEDIR/../../.cache/.cache_preferences")
else
    echo "Update check skipped: DL4MicEverywhere preferences could not be read." >&2
    exit 0
fi

# Determine the current branch/commit. Failure to check for updates is not a
# reason to prevent DL4MicEverywhere from launching.
if command -v git >/dev/null 2>&1; then
    branch_name=$(repo_git branch --show-current 2>/dev/null || true)
    local_commit=$(repo_git rev-parse HEAD 2>/dev/null || true)
else
    branch_name=$(sed -n 's|^ref: refs/heads/||p' "$REPO_ROOT/.git/HEAD" 2>/dev/null || true)
    local_commit=$(cat "$REPO_ROOT/.git/refs/heads/$branch_name" 2>/dev/null || true)
fi

if [ -z "$branch_name" ] || [ -z "$local_commit" ]; then
    show_check_unavailable "DL4MicEverywhere could not determine the current Git revision, so the update check was skipped."
    exit 0
fi

online_commit=$(curl -fsS --connect-timeout 5 --max-time 15 \
    "https://api.github.com/repos/HenriquesLab/DL4MicEverywhere/commits/${branch_name}" 2>/dev/null \
    | grep '"sha"' | head -1 | cut -d '"' -f 4)

if [ -z "$online_commit" ]; then
    show_check_unavailable "DL4MicEverywhere could not reach GitHub to check for updates."
    exit 0
fi

update_flag=1

if [ "$already_asked" = "1" ]; then
    if [ "$local_commit" = "$online_commit" ]; then
        show_notice "Up to date" "DL4MicEverywhere is already up to date."
        exit 0
    fi

    if [ "$flag_gui" -eq 1 ]; then
        update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked" 2>/dev/null || true)
        [ -n "$update_flag" ] || update_flag=1
    else
        read -r -p "A DL4MicEverywhere update is available. Update now? [y/N]: " answer
        case "$answer" in
            y|Y|yes|YES|Yes) update_flag=2 ;;
            *) update_flag=1 ;;
        esac
    fi
elif [ "$local_commit" != "$online_commit" ] && [[ "$update" == "Ask first"* ]]; then
    if [ "$flag_gui" -eq 1 ]; then
        update_flag=$(wish "$BASEDIR/../../tcl_tools/menubar/ask_update.tcl" "$already_asked" 2>/dev/null || true)
        [ -n "$update_flag" ] || update_flag=1
    else
        read -r -p "A DL4MicEverywhere update is available. Update now? [y/N]: " answer
        case "$answer" in
            y|Y|yes|YES|Yes) update_flag=2 ;;
            *) update_flag=1 ;;
        esac
    fi
elif [ "$local_commit" != "$online_commit" ] && [[ "$update" == "Automatically"* ]]; then
    update_flag=2
fi

if [ "$update_flag" -ne 2 ]; then
    exit 0
fi

if ! command -v git >/dev/null 2>&1; then
    show_notice "Update unavailable" "An update is available, but Git is not installed. The current DL4MicEverywhere installation was not changed and can continue to be used."
    exit 0
fi

echo "Updating DL4MicEverywhere ..."
if ! repo_git pull --ff-only; then
    show_notice "Update failed" "DL4MicEverywhere could not be updated. The current installation was kept unchanged as far as Git could preserve it. Review the Git output above, then try again later."
    exit 0
fi

show_notice "Successfully updated" "DL4MicEverywhere was updated successfully. It needs to be closed and launched again so the new version can start cleanly."
exit "$DL4ME_STATUS_UPDATE_COMPLETE"
