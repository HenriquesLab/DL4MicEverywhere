#! /usr/local/bin/wish

# This file is also used for friendly uninstall error messages after the main
# launcher window has closed.
if {[llength $argv] >= 2 && [lindex $argv 0] eq "--error"} {
    wm withdraw .
    tk_messageBox -type ok -icon error -title "Uninstall failed" \
        -message [lindex $argv 1]
    exit 0
}

# Confirmation dialog for removing DL4MicEverywhere.
# Output protocol (stdout):
#   0 = cancel
#   1 = uninstall application files only
#   2 = uninstall application files and DL4MicEverywhere Docker resources

set clean_docker 0

proc cancelUninstall {} {
    puts 0
    flush stdout
    exit 0
}

proc confirmUninstall {} {
    global clean_docker

    if {$clean_docker} {
        puts 2
    } else {
        puts 1
    }
    flush stdout
    exit 0
}

wm title . "Uninstall DL4MicEverywhere"
wm resizable . 1 0
wm protocol . WM_DELETE_WINDOW cancelUninstall
catch {wm attributes . -topmost 1}

frame .fr -padx 18 -pady 16
grid .fr -row 0 -column 0 -sticky nsew
grid columnconfigure . 0 -weight 1
grid columnconfigure .fr 0 -weight 1

font create uninstallTitleFont -family Helvetica -size 12 -weight bold

label .fr.title \
    -text "Uninstall DL4MicEverywhere?" \
    -font uninstallTitleFont \
    -anchor w
grid .fr.title -row 0 -column 0 -sticky ew -pady {0 10}

label .fr.warning \
    -text "This action is permanent and cannot be undone. DL4MicEverywhere and the files contained in its application folder will be removed from this computer." \
    -justify left -anchor w -wraplength 520
grid .fr.warning -row 1 -column 0 -sticky ew -pady {0 12}

checkbutton .fr.clean \
    -text "Also remove Docker images created or downloaded by DL4MicEverywhere" \
    -variable clean_docker \
    -anchor w
grid .fr.clean -row 2 -column 0 -sticky ew -pady {0 8}

label .fr.detail \
    -text "When selected, DL4MicEverywhere Docker containers associated with those images are removed as well so the images can be deleted cleanly. Docker Desktop, WSL, Tcl/Tk, and your input/output data outside the DL4MicEverywhere folder are not uninstalled." \
    -justify left -anchor w -wraplength 520
grid .fr.detail -row 3 -column 0 -sticky ew -pady {0 16}

frame .fr.buttons
grid .fr.buttons -row 4 -column 0 -sticky e

ttk::button .fr.buttons.cancel -text "Cancel" -command cancelUninstall
grid .fr.buttons.cancel -row 0 -column 0 -padx {0 8}

ttk::button .fr.buttons.uninstall -text "Uninstall" -command confirmUninstall
grid .fr.buttons.uninstall -row 0 -column 1

bind . <Escape> cancelUninstall

# Keep the dialog readable on small screens while allowing it to become a bit
# wider on large displays. Tk calculates the required height from its content.
update idletasks
set screen_width [winfo vrootwidth .]
set dialog_width [expr {min(590, max(480, $screen_width - 80))}]
set dialog_height [winfo reqheight .]
set x [expr {max(0, ($screen_width - $dialog_width) / 2)}]
set y [expr {max(0, ([winfo vrootheight .] - $dialog_height) / 2)}]
wm geometry . ${dialog_width}x${dialog_height}+${x}+${y}
wm minsize . 480 $dialog_height

raise .
focus .fr.buttons.cancel
