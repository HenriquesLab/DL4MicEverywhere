#! /usr/local/bin/wish

set title [lindex $argv 0]
set text [lindex $argv 1]

set text_length [string length $text]

# Define the shape of the window
set width [expr 10 + ( 7 * $text_length ) ]
set height 60

set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

label .fr.principal.text_1 -text "$text" 
place .fr.principal.text_1 -x [expr $width / 2 ] -y 1 -anchor n

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Yes" -command { puts 2; exit 0 }
pack .fr.yes -padx [expr $width / 10 ] -side left 
ttk::button .fr.no -text "No" -command { puts 3; exit 0 }
pack .fr.no -padx [expr $width / 10 ]  -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "$title"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
