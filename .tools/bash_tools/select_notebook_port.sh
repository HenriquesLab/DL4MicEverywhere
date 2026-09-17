#!/bin/bash

# Select a notebook port without confusing the WSL network namespace with the
# Windows host. On WSL, Docker Desktop publishes the container port on Windows,
# so a port must be free both inside Ubuntu and on the Windows host.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd -P)
WINDOWS_PORT_HELPER="$REPO_ROOT/.tools/windows_tools/check_windows_port.ps1"

PORT_MIN=8000
PORT_MAX=9000
PORT_RANGE_SIZE=$((PORT_MAX - PORT_MIN + 1))
initial_port="${1:-8888}"

if ! [[ "$initial_port" =~ ^[0-9]+$ ]] || [ "$initial_port" -lt 1 ] || [ "$initial_port" -gt 65535 ]; then
    echo "ERROR: Invalid notebook port '$initial_port'. Use a TCP port between 1 and 65535." >&2
    exit 2
fi

is_wsl_runtime() {
    if [ "${DL4ME_WINDOWS_WRAPPER:-0}" = "1" ]; then
        return 0
    fi

    if command -v systemd-detect-virt >/dev/null 2>&1 && [ "$(systemd-detect-virt 2>/dev/null)" = "wsl" ]; then
        return 0
    fi

    return 1
}

local_port_is_busy() {
    local candidate="$1"

    if command -v ss >/dev/null 2>&1; then
        ss -H -ltn "sport = :$candidate" 2>/dev/null | grep -q .
        return $?
    fi

    if command -v netstat >/dev/null 2>&1; then
        netstat -ltn 2>/dev/null | awk -v port=":$candidate" '
            $4 ~ port "$" && $6 == "LISTEN" { found=1; exit }
            END { exit(found ? 0 : 1) }
        '
        return $?
    fi

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$candidate" -sTCP:LISTEN >/dev/null 2>&1
        return $?
    fi

    echo "ERROR: Could not inspect local TCP ports because ss, netstat, and lsof are unavailable." >&2
    return 2
}

windows_port_status() {
    local candidate="$1"
    local helper_windows
    local result

    if ! command -v powershell.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
        echo "ERROR: WSL cannot inspect Windows host ports because powershell.exe or wslpath is unavailable." >&2
        return 2
    fi

    if [ ! -f "$WINDOWS_PORT_HELPER" ]; then
        echo "ERROR: Windows port-check helper is missing: $WINDOWS_PORT_HELPER" >&2
        return 2
    fi

    helper_windows=$(wslpath -w "$WINDOWS_PORT_HELPER") || return 2
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
        -File "$helper_windows" -Port "$candidate" >/dev/null 2>&1
    result=$?

    # PowerShell helper: 0 = free, 1 = occupied, anything else = probe error.
    case "$result" in
        0|1) return "$result" ;;
        *)
            echo "ERROR: Windows host port check failed for port $candidate (exit code $result)." >&2
            return 2
            ;;
    esac
}

port_is_available() {
    local candidate="$1"
    local local_result
    local windows_result

    local_port_is_busy "$candidate"
    local_result=$?
    case "$local_result" in
        0) return 1 ;;  # occupied inside Linux/WSL
        1) ;;
        *) return 2 ;;
    esac

    if is_wsl_runtime; then
        windows_port_status "$candidate"
        windows_result=$?
        case "$windows_result" in
            0) ;;
            1) return 1 ;;  # occupied by a native Windows listener
            *) return 2 ;;
        esac
    fi

    return 0
}

check_candidate() {
    local candidate="$1"
    local result

    port_is_available "$candidate"
    result=$?
    case "$result" in
        0)
            printf '%s\n' "$candidate"
            exit 0
            ;;
        1)
            echo "WARNING: Port $candidate is already allocated." >&2
            return 1
            ;;
        *)
            exit 4
            ;;
    esac
}

# Preserve an explicitly requested port outside the normal search window when it
# is free. If it is occupied, fall back to DL4MicEverywhere's normal 8000-9000
# range rather than walking thousands of ports or looping forever.
if [ "$initial_port" -lt "$PORT_MIN" ] || [ "$initial_port" -gt "$PORT_MAX" ]; then
    check_candidate "$initial_port"
    initial_result=$?
    if [ "$initial_result" -eq 0 ]; then
        exit 0
    fi
    if [ "$initial_result" -ne 1 ]; then
        exit "$initial_result"
    fi
    candidate=$PORT_MIN
else
    candidate=$initial_port
fi

# Search each preferred port at most once. This makes exhaustion deterministic
# instead of wrapping forever when every port in 8000-9000 is occupied.
attempt=0
while [ "$attempt" -lt "$PORT_RANGE_SIZE" ]; do
    check_candidate "$candidate"
    candidate_result=$?
    if [ "$candidate_result" -eq 0 ]; then
        exit 0
    fi
    if [ "$candidate_result" -ne 1 ]; then
        exit "$candidate_result"
    fi

    candidate=$((candidate + 1))
    if [ "$candidate" -gt "$PORT_MAX" ]; then
        candidate=$PORT_MIN
    fi
    attempt=$((attempt + 1))
done

echo "ERROR: No free notebook port was found between $PORT_MIN and $PORT_MAX." >&2
exit 3
