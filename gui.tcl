#! /usr/local/bin/wish

# Define the shape of the window
set width 645
set height 450
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
proc onSelectYaml {} {
    global yaml_types
    global yaml_path

    set file [tk_getOpenFile -filetypes $yaml_types -parent .]
    set yaml_path $file
}
proc onSelectIpynb {} {
    global ipynb_types
    global ipynb_path

    set file [tk_getOpenFile -filetypes $ipynb_types -parent .]
    set ipynb_path $file
}
proc onSelectTxt {} {
    global txt_types
    global txt_path

    set file [tk_getOpenFile -filetypes $txt_types -parent .]
    set txt_path $file
}

proc onSelectfolder {} {
    global folder_path

    set file [tk_chooseDirectory -parent .]
    set folder_path $file
}

proc onDone {} {
    global yaml_path
    global folder_path
    global ipynb_path
    global txt_path
    global gpu
    
    if {"$yaml_path" == ""} {
        tk_messageBox -type ok -icon error -title Error \
        -message "You need to specify a configuration file."
    } else {
        if {"$folder_path" == ""} {
            tk_messageBox -type ok -icon error -title Error \
            -message "You need to specify a folder."
        } else {
            if {"$ipynb_path" == ""} {
                set ipynb_path "-"
            }
            if {"$txt_path" == ""} {
                set txt_path "-"
            }

            puts "$yaml_path"
            puts "$folder_path"
            puts "$ipynb_path"
            puts "$txt_path"
            puts "$gpu"
            exit 0
        }
    }
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

ttk::button .fr.ok -text "Done" -command { onDone }
pack .fr.ok -side right

#### Manadatory argument section ######

# Define the text that will be the introduction to the window

label .fr.pnl.intro_1 -text "Welcome to DL4MicEverywhere!"
place .fr.pnl.intro_1 -x 10 -y 10
label .fr.pnl.intro_2 -text "Use the buttons below to select the configuration.yaml file and the data folder, these are mandatory."
place .fr.pnl.intro_2 -x 10 -y 30

# Define the button and display to load the path to the 'configuration.yaml' file

label .fr.pnl.yaml_label -text "Path to the configuration.yaml:"
place .fr.pnl.yaml_label -x 10 -y 60

entry .fr.pnl.yaml_entry -textvariable yaml_path -width 60
place .fr.pnl.yaml_entry -x 10 -y 80

button .fr.pnl.byp -text "Select" \
        -command "onSelectYaml"
place .fr.pnl.byp -x 560 -y 78

set yaml_path ""

# Define the button and display to load the path to the data folder

label .fr.pnl.folder_label -text "Path to the folder:"
place .fr.pnl.folder_label -x 10 -y 110

entry .fr.pnl.folder_entry -textvariable folder_path -width 60
place .fr.pnl.folder_entry -x 10 -y 130

button .fr.pnl.bdp -text "Select" \
        -command "onSelectfolder"
place .fr.pnl.bdp -x 560 -y 128


set folder_path ""

##### Optional argumwnts section #####

# Define the text for this section
label .fr.opt.intro_1 -text "These arguments are optional, there is no need to use them if it is not wanted."
place .fr.opt.intro_1 -x 10 -y 10
label .fr.opt.intro_2 -text "The default value for the GPU usage is false."
place .fr.opt.intro_2 -x 10 -y 30

# Define the button and display to load the path to the local notebook

label .fr.opt.ipynb_label -text "Path to the local notebook:"
place .fr.opt.ipynb_label -x 10 -y 60

entry .fr.opt.ipynb_entry -textvariable ipynb_path -width 60
place .fr.opt.ipynb_entry -x 10 -y 80

button .fr.opt.byp -text "Select" \
        -command "onSelectIpynb"
place .fr.opt.byp -x 560 -y 78


set ipynb_path ""

# Define the button and display to load the path to the data folder

label .fr.opt.txt_label -text "Path to the 'requirements.txt:"
place .fr.opt.txt_label -x 10 -y 110

entry .fr.opt.txt_entry -textvariable txt_path -width 60
place .fr.opt.txt_entry -x 10 -y 130

button .fr.opt.bdp -text "Select" \
        -command "onSelectTxt"
place .fr.opt.bdp -x 560 -y 128

set txt_path ""

# Define the checkbutton for the GPU usage

checkbutton .fr.opt.gpu -text "Allow GPU" -variable gpu
place .fr.opt.gpu -x 10 -y 165

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen

wm title . "DL4MicEverywhere"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}