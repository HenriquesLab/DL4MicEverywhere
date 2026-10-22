#!/bin/bash

# Classify why Docker can or cannot be used by the current user. Source this
# file and call dl4me_docker_state; it prints one of:
#   ready            `docker info` works (Docker Engine or Docker Desktop).
#   no_permission    The daemon socket exists but this user may not access it.
#   engine_stopped   Docker Engine (systemd service) is installed but not running.
#   desktop_stopped  Docker Desktop is the configured engine but is not running.
#   unknown          Anything else; DL4ME_DOCKER_INFO_ERROR holds Docker's message.
#
# The classification relies on exit codes and Docker's own stable error text,
# never on localized system messages.

DL4ME_DOCKER_INFO_ERROR=""

dl4me_is_wsl() {
    [[ "${OSTYPE:-}" == "linux-gnu"* ]] || return 1
    command -v systemd-detect-virt >/dev/null 2>&1 || return 1
    [[ "$(systemd-detect-virt 2>/dev/null)" == "wsl"* ]]
}

dl4me_docker_state() {
    local error_output

    if error_output=$(docker info 2>&1 >/dev/null); then
        echo "ready"
        return 0
    fi
    DL4ME_DOCKER_INFO_ERROR="$error_output"

    case "$error_output" in
        *"permission denied"*)
            echo "no_permission"
            return 0
            ;;
    esac

    if [[ "${OSTYPE:-}" == "darwin"* ]] || dl4me_is_wsl; then
        # macOS and WSL always use Docker Desktop.
        echo "desktop_stopped"
        return 0
    fi

    if [[ "${OSTYPE:-}" == "linux-gnu"* ]]; then
        if [ "$(docker context show 2>/dev/null)" = "desktop-linux" ]; then
            echo "desktop_stopped"
            return 0
        fi
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl cat docker.service >/dev/null 2>&1 || systemctl cat docker.socket >/dev/null 2>&1; then
                echo "engine_stopped"
                return 0
            fi
            if systemctl --user cat docker-desktop.service >/dev/null 2>&1; then
                echo "desktop_stopped"
                return 0
            fi
        fi
    fi

    echo "unknown"
}
