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

# Apple's bundled Tcl/Tk 8.5 (/usr/bin/wish -> /System/Library/Frameworks/Tk.framework)
# is deprecated, and macOS 15 refuses to launch it ("Launch Constraint Violation").
# Only a separately installed wish (Homebrew tcl-tk, or another Tk 8.6+ build)
# is usable. Checked by path so the GUI toolkit does not have to be started.
dl4me_macos_wish_usable() {
    local wish_path resolved
    wish_path=$(command -v wish 2>/dev/null) || return 1
    resolved="$wish_path"
    if command -v dl4me_realpath >/dev/null 2>&1; then
        resolved=$(dl4me_realpath "$wish_path" 2>/dev/null) || resolved="$wish_path"
    fi
    case "$wish_path:$resolved" in
        /usr/bin/*|/System/Library/*|*:/usr/bin/*|*:/System/Library/*) return 1 ;;
    esac
    return 0
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
