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

label .fr.principal.text_1 -text "A Docker image with this tag is available on Docker Hub." 
place .fr.principal.text_1 -relx 0.02 -rely 0.0
label .fr.principal.text_2 -text "Would you like to:"
place .fr.principal.text_2 -relx 0.02 -rely 0.1
label .fr.principal.text_3 -font myFont -text "1. Download the image from Docker Hub?"
place .fr.principal.text_3 -relx 0.02 -rely 0.25
label .fr.principal.text_4 -text "  - Pros: Quicker setup, no need to build."
place .fr.principal.text_4 -relx 0.02 -rely 0.35
label .fr.principal.text_5 -text "  - Cons: No custom setup are allowed."
place .fr.principal.text_5 -relx 0.02 -rely 0.45
label .fr.principal.text_6 -font myFont -text "2. Build the image on your computer?"
place .fr.principal.text_6 -relx 0.02 -rely 0.55
label .fr.principal.text_7 -text "  - Pros: Full control, customize as needed."
place .fr.principal.text_7 -relx 0.02 -rely 0.65
label .fr.principal.text_8 -text "  - Cons: Takes more time."
place .fr.principal.text_8 -relx 0.02 -rely 0.75
label .fr.principal.text_9 -text "Choose an option bellow:"
place .fr.principal.text_9 -relx 0.02 -rely 0.9

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Download Image" -command { puts 3; exit 0 }
pack .fr.yes -padx 50 -side left 

ttk::button .fr.no -text "Build Locally" -command { puts 2; exit 0 }
pack .fr.no -padx 50 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "There is an online Docker image"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
