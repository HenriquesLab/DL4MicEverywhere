#! /usr/local/bin/wish

# Define the shape of the window
set width 340
set height 85
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

label .fr.principal.text_1 -text "Docker Desktop is not running." 
place .fr.principal.text_1 -relx 0.02 -rely 0.05
label .fr.principal.text_2 -text "Do you want to launch it?"
place .fr.principal.text_2 -relx 0.02 -rely 0.5

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Yes" -command { puts 3; exit 0 }
pack .fr.yes -padx 30 -side left 

ttk::button .fr.no -text "No" -command { puts 2; exit 0 }
pack .fr.no -padx 30 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Docker Desktop not running"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
