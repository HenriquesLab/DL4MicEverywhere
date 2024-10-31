#! /usr/local/bin/wish

# Set the BASEDIR
set basedir [lindex $argv 0]

# Check if there is cache information
set filename "$basedir/.tools/.cache_settings"
set fexist [file exist $filename]

if {"$fexist" == "1"} {
    #  read the file one line at a time
    set fp [open "$filename" r]
    while { [gets "$fp" data] >= 0 } {
        set e [split "$data" ":"]
        set varname [string trim [lindex "$e" 0]]
        set varvalue [string trim [lindex "$e" 1]]
        eval "set cache_$varname \"$varvalue\""
    }
    close "$fp"
} else {
    set cache_containerization ""
    set cache_update ""
    set cache_clean ""
}

proc onSave {} {
    global selectedContSystem
    global selectedUpdate 
    global selectedClean 

    if {"$selectedContSystem" == "-"} {
        tk_messageBox -type ok -icon error -title Error \
        -message "You need to choose a Constainerisation system."
    } else {
        if {"$selectedUpdate" == "-"} {
            tk_messageBox -type ok -icon error -title Error \
            -message "You need to choose an option for updating."
        } else {
            if {"$selectedClean" == "-"} {
                tk_messageBox -type ok -icon error -title Error \
                -message "You need to choose an option for cleaning."
            } else {
                puts "$selectedContSystem"
                puts "$selectedUpdate"
                puts "$selectedClean"
                
                exit 0
            }
        }
    }
}

# Define the shape of the window
set width 440
set height 220
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

# Read the OS of the computer
set operative_system [lindex $argv 0]
set is_mac 0
set is_linux 0

# Check if it is mac to change the display
if {[string match darwin* $operative_system]} {
    set is_mac 1
}
# Check if it is linux to change the display
if {[string match linux-gnu* $operative_system]} {
    set is_linux 1
}

##### Define the frame #####

frame .fr
pack .fr -fill both -expand 1

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

# Define the font
font create myFont -size 10 -weight bold

##### Settings section #####

### Containerisation system

label .fr.principal.notebook_text_! -text "Choose the installed and used containerisation backend."

label .fr.principal.notebook_label -text "Containerisation system:"
place .fr.principal.notebook_label -relx 0.03 -rely 0.02

set selectedContSystem ${cache_containerization}
set listContSystem [list "Docker" "Singularity"]

ttk::combobox .fr.principal.containerization -values $listContSystem -textvariable selectedContSystem -state readonly
place .fr.principal.containerization -relx 0.48 -rely 0.02

### How to update DL4MicEverywhere

label .fr.principal.update_label -text "Update DL4MicEverywhere:"
place .fr.principal.update_label -relx 0.03 -rely 0.17

set selectedUpdate ${cache_update}
set listUpdate [list "Automatically" "Ask first" "Never"]

ttk::combobox .fr.principal.update -values $listUpdate -textvariable selectedUpdate -state readonly
place .fr.principal.update -relx 0.48 -rely 0.17

### How to clean Docker

label .fr.principal.clean_label -text "Clean Docker space:"
place .fr.principal.clean_label -relx 0.03 -rely 0.32

set selectedClean ${cache_clean}
set listClean [list "Automatically" "Manually"]

ttk::combobox .fr.principal.clean -values $listUpdate -textvariable selectedClean -state readonly
place .fr.principal.clean -relx 0.48 -rely 0.32

##### Buttons section #####

# Define the buttons to submit the information or close the program

ttk::button .fr.save -text "Save" -command { onSave }
pack .fr.save -padx 6 -pady 2 -side right 
ttk::button .fr.cancel -text "Cancel" -command { exit 0 }
pack .fr.cancel -padx 0 -pady 2 -side right

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "Settings"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
