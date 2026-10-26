#!/bin/bash

# Every DL4MicEverywhere dialog is a separate wish process started from this
# terminal. On macOS its window can still open behind the Terminal window
# (window_utils.tcl tries to keep it in front), so tell the user that a window
# is waiting. The hint goes to stderr because callers read the dialog's answer
# from stdout.
dl4me_announce_dialog() {
    if [[ "${OSTYPE:-}" == "darwin"* ]]; then
        echo "A DL4MicEverywhere window is waiting for your answer. If you cannot see it, please check your open windows." >&2
    fi
}

dl4me_wish() {
    dl4me_announce_dialog
    wish "$@"
}
