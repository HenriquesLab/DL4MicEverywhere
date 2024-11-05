#! /usr/local/bin/wish

set already_asked [lindex $argv 0]

# Define the shape of the window
if {"$already_asked" == "0"} {
    set width 400
    set height 80
} else {
    set width 400
    set height 60
}
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

if {"$already_asked" == "0"} {
    label .fr.principal.text_1 -text "Your DL4MicEverywhere version seems to not be up to date." 
    place .fr.principal.text_1 -relx 0.02 -rely 0.1
    label .fr.principal.text_2 -text "Do you want to update DL4MicEverywhere?" 
    place .fr.principal.text_2 -relx 0.02 -rely 0.5
} else {
    label .fr.principal.text_1 -text "Are you sure that you want to update DL4MicEverywhere?" 
    place .fr.principal.text_1 -relx 0.02 -rely 0.1
}

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Yes" -command { puts 2; exit 0 }
pack .fr.yes -padx 30 -side left 

ttk::button .fr.no -text "No" -command { puts 1; exit 0 }
pack .fr.no -padx 30 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Do you want to update?"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
