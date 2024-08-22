#! /usr/local/bin/wish

# Define the shape of the window
set width 550
set height 150
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

label .fr.principal.text_1 -text "The installation has been successfully completed." 
place .fr.principal.text_1 -relx 0.02 -rely 0.01
label .fr.principal.text_2 -text "Would you like to restart your system now, or would you prefer to restart it later?"
place .fr.principal.text_2 -relx 0.02 -rely 0.31
label .fr.principal.text_3 -text "It's recommended to restart now to apply all changes."
place .fr.principal.text_3 -relx 0.02 -rely 0.61
label .fr.principal.text_4 -text "If you choose to restart later, please remember to manually restart your computer."
place .fr.principal.text_4 -relx 0.02 -rely 0.81

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Restart Now" -command { puts 2; exit 0 }
pack .fr.yes -padx 30 -side left 

ttk::button .fr.no -text "Restart Later" -command { puts 3; exit 0 }
pack .fr.no -padx 30 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Installation Complete"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
