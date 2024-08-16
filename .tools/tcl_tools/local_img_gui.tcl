#! /usr/local/bin/wish

# Define the shape of the window
set width 460
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

label .fr.principal.text_1 -text "A Docker image with this tag already exists on your computer."
place .fr.principal.text_1 -relx 0.02 -rely 0.02
label .fr.principal.text_2 -text "Would you like to:"
place .fr.principal.text_2 -relx 0.02 -rely 0.11
label .fr.principal.text_3 -font myFont  -text "1. Use the existing image?"
place .fr.principal.text_3 -relx 0.02 -rely 0.25
label .fr.principal.text_4 -text "  - Pros: Faster, no need to rebuild."
place .fr.principal.text_4 -relx 0.02 -rely 0.35
label .fr.principal.text_5 -text "  - Cons: May not include the latest changes."
place .fr.principal.text_5 -relx 0.02 -rely 0.45
label .fr.principal.text_6 -font myFont  -text "2. Build and replace the existing image?"
place .fr.principal.text_6 -relx 0.02 -rely 0.55
label .fr.principal.text_7 -text "  - Pros: Ensures you have the latest version."
place .fr.principal.text_7 -relx 0.02 -rely 0.65
label .fr.principal.text_8 -text "  - Cons: Takes more time, and will overwrite current image."
place .fr.principal.text_8 -relx 0.02 -rely 0.75
label .fr.principal.text_9 -text "Choose an option bellow:" 
place .fr.principal.text_9 -relx 0.02 -rely 0.9 

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Use Existing Image" -command { puts 1; exit 0 }
pack .fr.yes -padx 40 -side left 

ttk::button .fr.no -text "Build and Replace" -command { puts 2; exit 0 }
pack .fr.no -padx 40 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "There is a local Docker image"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
