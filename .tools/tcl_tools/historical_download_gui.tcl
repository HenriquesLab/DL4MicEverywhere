#! /usr/local/bin/wish

set docker_tag [lindex $argv 0]

set width 720
set height 175
set width_offset [expr {([winfo vrootwidth .] - $width) / 2}]
set height_offset [expr {([winfo vrootheight .] - $height) / 2}]

proc finish {code} {
    puts $code
    exit 0
}

wm protocol . WM_DELETE_WINDOW {finish 0}
wm title . "Download older Docker image"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
wm minsize . 620 160

frame .fr -padx 16 -pady 14
pack .fr -fill both -expand 1

grid columnconfigure .fr 0 -weight 1

label .fr.title -font {TkDefaultFont 10 bold} \
    -text "For older versions, only downloading from Docker Hub is available."
grid .fr.title -row 0 -column 0 -sticky w

label .fr.tag -text "Image: $docker_tag" -anchor w -wraplength 680 -justify left
grid .fr.tag -row 1 -column 0 -sticky ew -pady {10 0}

label .fr.question \
    -text "Do you agree to continue and download this published image?" \
    -anchor w -wraplength 680 -justify left
grid .fr.question -row 2 -column 0 -sticky ew -pady {12 14}

frame .fr.buttons
grid .fr.buttons -row 3 -column 0 -sticky ew
grid columnconfigure .fr.buttons 0 -weight 1
grid columnconfigure .fr.buttons 1 -weight 1

ttk::button .fr.buttons.cancel -text "Cancel" -command {finish 0}
ttk::button .fr.buttons.accept -text "Accept" -command {finish 3}

grid .fr.buttons.cancel -row 0 -column 0 -padx 8
grid .fr.buttons.accept -row 0 -column 1 -padx 8
