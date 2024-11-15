#! /usr/local/bin/wish

# Set the BASEDIR
set basedir [lindex $argv 0]

# Check if the construct.yaml file is accessible
set construct "$basedir/construct.yaml"
set construct_exist [file exist $construct]

puts $basedir

# Get DL4MicEverywhere version if possible and define the window title
if {"$construct_exist" == "1"} {
    catch {exec /bin/bash "$basedir/.tools/bash_tools/get_dl4miceverywhere_version.sh"} output
    set dl4miceverywhere_version "$output"
} else {
    set dl4miceverywhere_version "ERROR"
}

# Define the shape of the window
set width 500
set height 240
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

frame .fr
pack .fr -fill both -expand 1

##### Buttons section #####

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

# Define the font
font create myFont -size 10 -weight bold

label .fr.principal.intro_1 -text "DL4MicEverywhere is a platform that offers researchers an easy-to-use gateway"
place .fr.principal.intro_1 -x [expr $width / 2 ] -y 10 -anchor n

label .fr.principal.intro_2 -text "to cutting-edge deep learning techniques for bioimage analysis. It features"
place .fr.principal.intro_2 -x [expr $width / 2 ] -y 30 -anchor n

label .fr.principal.intro_3 -text "interactive Jupyter notebooks with user-friendly graphical interfaces that "
place .fr.principal.intro_3 -x [expr $width / 2 ] -y 50 -anchor n

label .fr.principal.intro_4 -text "require no coding skills. The platform utilizes Docker containers to ensure"
place .fr.principal.intro_4 -x [expr $width / 2 ] -y 70 -anchor n

label .fr.principal.intro_5 -text "portability and reproducibility, guaranteeing smooth operation across various"
place .fr.principal.intro_5 -x [expr $width / 2 ] -y 90 -anchor n

label .fr.principal.intro_6 -text "computing environments."
place .fr.principal.intro_6 -x [expr $width / 2 ] -y 110 -anchor n


label .fr.principal.intro_7 -text "Your DL4MicEverywhere version is:"
place .fr.principal.intro_7 -x [expr $width / 2 ] -y 150 -anchor n
label .fr.principal.intro_8 -text "$dl4miceverywhere_version"
place .fr.principal.intro_8 -x [expr $width / 2 ] -y 170 -anchor n

# Define the buttons to submit the information or close the program

ttk::button .fr.yes -text "Done" -command { exit 0 }
pack .fr.yes -side bottom 

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Information"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
