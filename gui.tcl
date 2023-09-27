#! /usr/local/bin/wish

# Define the shape of the window
set width 645
set height 350
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

# Define the types for the file searching 
set yaml_types {
    {"All yaml files"     {.yaml } }
}
set ipynb_types {
    {"All ipynb files"     {.ipynb } }
}
set txt_types {
    {"All txt files"     {.txt } }
}

# Define the selection functions (yaml, folder, ipynb and txt) 
proc onSelectYaml {yaml_path} {
    global yaml_types
    set file [tk_getOpenFile -filetypes $yaml_types -parent .]
    set yaml_path $file
}
proc onSelectIpynb {ipynb_path} {
    global ipynb_types
    set file [tk_getOpenFile -filetypes $ipynb_types -parent .]
    set ipynb_path $file
}
proc onSelectTxt {txt_path} {
    global txt_types
    set file [tk_getOpenFile -filetypes $txt_types -parent .]
    set txt_path $file
}

proc onSelectfolder {folder_path} {
    set file [tk_chooseDirectory -parent .]
    set folder_path $file
}

##### Define the frames of the window #####

# Define the frames to display the information
# It will be divided in three sections (mandatory arguments, optional and "Done" and "Cancel" buttons.)

frame .fr
pack .fr -fill both -expand 1

frame .fr.pnl -relief raised -borderwidth 1
pack .fr.pnl -fill both -expand 1

frame .fr.opt -relief raised -borderwidth 1
pack .fr.opt -fill both -expand 1

##### Buttons section #####

# Define the buttons to submit the information or close the program

ttk::button .fr.cb -text "Close" -command { exit 1 }
pack .fr.cb -padx 5 -pady 5 -side right 

ttk::button .fr.ok -text "Done" -command { exit 0 }
pack .fr.ok -side right

#### Manadatory argument section ######

# Define the text that will be the introduction to the window

label .fr.pnl.intro_1 -text "Welcome to DL4MicEverywhere!"
place .fr.pnl.intro_1 -x 10 -y 10
label .fr.pnl.intro_2 -text "Use the buttons below to select the configuration.yaml file and the data folder, these are mandatory."
place .fr.pnl.intro_2 -x 10 -y 30

# Define the button and display to load the path to the 'configuration.yaml' file

button .fr.pnl.byp -text "Select" \
        -command "onSelectYaml yaml_path"
place .fr.pnl.byp -x 560 -y 58

entry .fr.pnl.yaml_entry -textvariable yaml_path -width 60
place .fr.pnl.yaml_entry -x 10 -y 60

set yaml_path "Path to the configuration.yaml"

# Define the button and display to load the path to the data folder

button .fr.pnl.bdp -text "Select" \
        -command "onSelectfolder folder_path"
place .fr.pnl.bdp -x 560 -y 88

entry .fr.pnl.folder_entry -textvariable folder_path -width 60
place .fr.pnl.folder_entry -x 10 -y 90

set folder_path "Path to the folder"

##### Optional argumwnts section #####

# Define the text for this section
label .fr.opt.intro_1 -text "These arguments are optional, there is no need to use them if it is not wanted."
place .fr.opt.intro_1 -x 10 -y 10
label .fr.opt.intro_2 -text "The default value for the GPU usage is false."
place .fr.opt.intro_2 -x 10 -y 30

# Define the button and display to load the path to the local notebook

button .fr.opt.byp -text "Select" \
        -command "onSelectIpynb ipynb_path"
place .fr.opt.byp -x 560 -y 58

entry .fr.opt.ipynb_entry -textvariable ipynb_path -width 60
place .fr.opt.ipynb_entry -x 10 -y 60

set ipynb_path "Path to the local notebook"

# Define the button and display to load the path to the data folder

button .fr.opt.bdp -text "Select" \
        -command "onSelectTxt txt_path"
place .fr.opt.bdp -x 560 -y 88

entry .fr.opt.txt_entry -textvariable txt_path -width 60
place .fr.opt.txt_entry -x 10 -y 90

set txt_path "Path to the 'requirements.txt'"

# Define the checkbutton for the GPU usage

checkbutton .fr.opt.gpu -text "Allow GPU" -variable gpu
place .fr.opt.gpu -x 10 -y 120

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen

wm title . "DL4MicEverywhere"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}