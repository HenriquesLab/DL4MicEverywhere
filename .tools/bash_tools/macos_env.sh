#!/bin/bash

# Runtime environment discovery for macOS. DL4MicEverywhere does not modify
# shell startup files just to make its own dependencies visible.

dl4me_path_prepend() {
    local directory="$1"
    [ -d "$directory" ] || return 0
    case ":$PATH:" in
        *":$directory:"*) ;;
        *) PATH="$directory:$PATH" ;;
    esac
    export PATH
}

dl4me_find_brew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return 0
    fi
    if [ -x /opt/homebrew/bin/brew ]; then
        printf '%s\n' /opt/homebrew/bin/brew
        return 0
    fi
    if [ -x /usr/local/bin/brew ]; then
        printf '%s\n' /usr/local/bin/brew
        return 0
    fi
    return 1
}

dl4me_setup_macos_path() {
    local brew_bin tcl_prefix docker_app

    case "${OSTYPE:-}" in
        darwin*) ;;
        *) return 0 ;;
    esac

    # Homebrew's supported default prefixes differ by Mac architecture.
    dl4me_path_prepend /opt/homebrew/bin
    dl4me_path_prepend /opt/homebrew/sbin
    dl4me_path_prepend /usr/local/bin
    dl4me_path_prepend /usr/local/sbin

    docker_app="${DL4ME_DOCKER_APP_PATH:-/Applications/Docker.app}"
    dl4me_path_prepend "$docker_app/Contents/Resources/bin"

    brew_bin=$(dl4me_find_brew 2>/dev/null || true)
    if [ -n "$brew_bin" ]; then
        tcl_prefix=$("$brew_bin" --prefix tcl-tk 2>/dev/null || true)
        if [ -n "$tcl_prefix" ]; then
            dl4me_path_prepend "$tcl_prefix/bin"
        fi
    fi
}
