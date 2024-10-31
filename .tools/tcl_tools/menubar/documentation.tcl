#! /usr/local/bin/wish

# Define the shape of the window
set width 440
set height 220
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

# Define the font
font create myFont -size 10 -weight bold

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Done" -command { exit 0 }
pack .fr.yes -side bottom 

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Documentation"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
