#!/bin/bash
# Backward-compatible shim for the historical misspelled filename.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
exec /bin/bash "$SCRIPT_DIR/homebrew.sh" "$@"
