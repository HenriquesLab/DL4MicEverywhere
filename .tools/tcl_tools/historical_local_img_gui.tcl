#! /usr/local/bin/wish

set docker_tag [lindex $argv 0]

set width 760
set height 195
set width_offset [expr {([winfo vrootwidth .] - $width) / 2}]
set height_offset [expr {([winfo vrootheight .] - $height) / 2}]

proc finish {code} {
    puts $code
    exit 0
}

wm protocol . WM_DELETE_WINDOW {finish 0}
wm title . "Older Docker image already available"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
wm minsize . 660 180

frame .fr -padx 16 -pady 14
pack .fr -fill both -expand 1

grid columnconfigure .fr 0 -weight 1

label .fr.title -font {TkDefaultFont 10 bold} \
    -text "This older Docker image already exists on your computer."
grid .fr.title -row 0 -column 0 -sticky w

label .fr.tag -text "Image: $docker_tag" -anchor w -wraplength 720 -justify left
grid .fr.tag -row 1 -column 0 -sticky ew -pady {8 0}

label .fr.info \
    -text "Older versions are not built from the current configuration. You can use the existing local image or replace it by downloading the published image from Docker Hub." \
    -anchor w -wraplength 720 -justify left
grid .fr.info -row 2 -column 0 -sticky ew -pady {10 12}

frame .fr.buttons
grid .fr.buttons -row 3 -column 0 -sticky ew -pady {8 0}
grid columnconfigure .fr.buttons 0 -weight 1
grid columnconfigure .fr.buttons 1 -weight 1
grid columnconfigure .fr.buttons 2 -weight 1

ttk::button .fr.buttons.use -text "Use Existing Image" -command {finish 1}
ttk::button .fr.buttons.download -text "Download from Docker Hub" -command {finish 3}
ttk::button .fr.buttons.cancel -text "Cancel" -command {finish 0}

grid .fr.buttons.use -row 0 -column 0 -padx 5
grid .fr.buttons.download -row 0 -column 1 -padx 5
grid .fr.buttons.cancel -row 0 -column 2 -padx 5
