#!/bin/bash

# DL4MicEverywhere macOS wrapper.
# Keep platform-specific bootstrap/status UX here and share the application
# implementation with Linux_launch.sh.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)" || exit 1
source "$SCRIPT_DIR/.tools/bash_tools/path_utils.sh" || exit 1
BASEDIR=$(dl4me_realpath "$SCRIPT_DIR") || exit 1
source "$BASEDIR/.tools/bash_tools/launcher_status.sh" || exit 1
source "$BASEDIR/.tools/bash_tools/macos_env.sh" || exit 1

dl4me_setup_macos_path

pause_before_close() {
    if [ "${DL4ME_TEST_NO_PAUSE:-0}" = "1" ]; then
        return 0
    fi
    if [ -t 0 ]; then
        printf '\nPress Return to close this launcher...'
        IFS= read -r _
    fi
}

finish_success() {
    pause_before_close
    exit 0
}

finish_failure() {
    pause_before_close
    exit 1
}

print_banner() {
    printf '\n============================================================\n'
    printf '%s\n' "$1"
    printf '============================================================\n\n'
}

# Preserve the shared controlled/handled status codes so this wrapper can give
# macOS users the same contextual messages as the Windows wrapper.
DL4ME_MACOS_WRAPPER=1 /bin/bash "$BASEDIR/Linux_launch.sh"
LAUNCH_RESULT=$?

case "$LAUNCH_RESULT" in
    0)
        exit 0
        ;;
    42)
        print_banner "DL4MicEverywhere uninstalled successfully"
        printf '%s\n' "The application folder was removed successfully."
        printf '%s\n' "Any Docker cleanup you selected was completed before removal."
        finish_success
        ;;
    90)
        print_banner "Restart required"
        printf '%s\n' "DL4MicEverywhere finished installing prerequisites, but a restart is still required."
        printf '%s\n' "Restart your Mac, then launch DL4MicEverywhere again."
        finish_success
        ;;
    91)
        print_banner "Restart requested"
        printf '%s\n' "DL4MicEverywhere requested a system restart to finish prerequisite setup."
        finish_success
        ;;
    92)
        print_banner "DL4MicEverywhere closed normally"
        printf '%s\n' "You closed the graphical interface. No error occurred."
        printf '%s\n' "Docker Desktop is intentionally left running and no Docker data was removed."
        finish_success
        ;;
    93)
        print_banner "DL4MicEverywhere updated successfully"
        printf '%s\n' "The application files were updated successfully."
        printf '%s\n' "Launch DL4MicEverywhere again so the new version starts in a clean process."
        finish_success
        ;;
    94)
        print_banner "DL4MicEverywhere operation cancelled"
        printf '%s\n' "You cancelled the current operation. No error occurred and no further action is required."
        finish_success
        ;;
    95)
        print_banner "Selected Docker image is not available"
        printf '%s\n' "The requested historical Docker image could not be found."
        printf '%s\n' "Choose another available version and try again."
        finish_failure
        ;;
    96)
        print_banner "DL4MicEverywhere needs an input or configuration change"
        printf '%s\n' "A required path, option, or configuration value was missing or invalid."
        printf '%s\n' "Review the detailed message above, correct it, and launch again."
        finish_failure
        ;;
    97)
        print_banner "Dependency preparation failed"
        printf '%s\n' "DL4MicEverywhere could not prepare the deterministic Python dependency lock."
        printf '%s\n' "Review the resolver details above before retrying."
        finish_failure
        ;;
    98)
        print_banner "Docker image preparation failed"
        printf '%s\n' "The Docker image could not be built, pulled, or prepared successfully."
        printf '%s\n' "Review the Docker output above before retrying."
        finish_failure
        ;;
    99)
        print_banner "Docker image validation failed"
        printf '%s\n' "The image was created or obtained, but its post-build validation did not pass."
        printf '%s\n' "Review the dependency/validation details above."
        finish_failure
        ;;
    100)
        print_banner "Notebook container ended with an error"
        printf '%s\n' "Docker started the notebook container, but the notebook runtime returned an unexpected status."
        printf '%s\n' "Review the Jupyter/Docker output above for the underlying error."
        finish_failure
        ;;
    101)
        print_banner "DL4MicEverywhere update failed"
        printf '%s\n' "The update did not complete. The current installation was kept as safely as possible."
        printf '%s\n' "Review the Git output above and try again later."
        finish_failure
        ;;
    102)
        print_banner "DL4MicEverywhere uninstall was not completed"
        printf '%s\n' "The uninstaller stopped safely and kept the application folder in place."
        printf '%s\n' "Review the detailed message above, then retry when the blocking condition is resolved."
        finish_failure
        ;;
    103)
        print_banner "A macOS prerequisite is not ready"
        printf '%s\n' "DL4MicEverywhere could not complete one of its prerequisite checks."
        printf '%s\n' "Review the specific Homebrew, Tcl/Tk, Docker Desktop, or system message above and retry."
        finish_failure
        ;;
    104)
        print_banner "No notebook port is available"
        printf '%s\n' "DL4MicEverywhere could not find a free local port in its supported range (8000-9000)."
        printf '%s\n' "Close an application using ports in that range, or free a port and try again."
        finish_failure
        ;;
    *)
        print_banner "DL4MicEverywhere ended unexpectedly on macOS"
        printf 'The shared launcher returned exit code %s.\n\n' "$LAUNCH_RESULT"
        printf '%s\n' "This status is not one of DL4MicEverywhere's controlled or handled outcomes."
        printf '%s\n' "Review the terminal output above for the first error message."
        finish_failure
        ;;
esac
