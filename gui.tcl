#! /usr/local/bin/wish

# Define the shape of the window
set width 650
set height 700
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

proc onSelectData {} {
    global data_path

    set file [tk_chooseDirectory -parent .]
    set data_path $file
}

proc onSelectResult {} {
    global result_path

    set file [tk_chooseDirectory -parent .]
    set result_path $file
}

proc onDone {} {

    global data_path
    global result_path

    if {"$data_path" == ""} {
        tk_messageBox -type ok -icon error -title Error \
        -message "ADVANCED MODE: You need to specify a data folder."
    } else {
        if {"$result_path" == ""} {
            tk_messageBox -type ok -icon error -title Error \
            -message "ADVANCED MODE: You need to specify a result folder."
        } else {
            global advanced_options
            
            if {"$advanced_options" == 0} {
                # The user has selected the simple mode
                global simpleNotebook
                if {"$simpleNotebook" == "-"} {
                    tk_messageBox -type ok -icon error -title Error \
                    -message "SIMPLE MODE: You need to specify a notebook."
                } else {
                    puts "$advanced_options"
                    puts "$data_path"
                    puts "$result_path"
                    puts "$simpleNotebook"
                    
                    exit 0
                }
            } else {
                # The user has selected the advanced mode
                global yaml_path
                global ipynb_path
                global txt_path
                global gpu
                global tag
                
                if {"$yaml_path" == ""} {
                    tk_messageBox -type ok -icon error -title Error \
                    -message "ADVANCED MODE: You need to specify a configuration file."
                } else {
                    if {"$ipynb_path" == ""} {
                        set ipynb_path "-"
                    }
                    if {"$txt_path" == ""} {
                        set txt_path "-"
                    }
                    if {"$tag" == ""} {
                        set txt_path "-"
                    }

                    puts "$advanced_options"
                    puts "$data_path"
                    puts "$result_path"

                    puts "$yaml_path"
                    puts "$ipynb_path"
                    puts "$txt_path"
                    puts "$gpu"
                    puts "$tag"
                    
                    exit 0
                }
            }
        }
    }
}

proc onAdvanced {} {
    global advanced_options
    if {"$advanced_options" == 0} {
        set advanced_options 1
        pack .fr.advanced -fill both -expand 1
    } else {
        set advanced_options 0
        pack .fr.advanced -fill both -expand 0
    }

    place .fr.principal.notebook_label -relx 0.01 -rely [expr 0.2 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebooks -relx 0.01 -rely [expr 0.28 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebook_description -relx 0.35 -rely [expr 0.2 / ( 2 - $advanced_options ) ]
    place .fr.principal.update_text -relx 0.01 -rely [expr 0.37 / ( 2 - $advanced_options ) ]

    place .fr.principal.data_label -relx 0.01 -rely [expr 0.45 / ( 2 - $advanced_options ) ]
    place .fr.principal.data_entry -relx 0.01 -rely [expr 0.52 / ( 2 - $advanced_options ) ]
    place .fr.principal.data_btn -relx 0.87 -rely [expr 0.515 / ( 2 - $advanced_options ) ]

    place .fr.principal.result_label -relx 0.01 -rely [expr 0.6 / ( 2 - $advanced_options ) ]
    place .fr.principal.result_entry -relx 0.01 -rely [expr 0.67 / ( 2 - $advanced_options ) ]
    place .fr.principal.result_btn -relx 0.87 -rely [expr 0.665 / ( 2 - $advanced_options ) ]

}

proc parseYaml {notebook_name} {
    global update

    # Read a yaml file
    catch {exec /bin/bash parse_yaml.sh "$notebook_name"} output

    set arguments [split $output \n]

    # Get the arguments that we want
    .fr.principal.notebook_description delete 0.0 end
    .fr.principal.notebook_description insert end [lindex $arguments 1]

    if {[lindex $arguments 0] == 1} {
        set update "There is an updated version of this notebook."
    } else {
        set update ""
    }
}


# The flag that indicates if "Advanced options" will be used
set advanced_options 0
set update ""

##### Define the frames of the window #####

# Define the frames to display the information
# It will be divided in three sections (mandatory arguments, advanced and "Run" and "Cancel" buttons.)

frame .fr
pack .fr -fill both -expand 1

frame .fr.principal -relief raised -borderwidth 1
pack .fr.principal -fill both -expand 1

frame .fr.advanced -relief raised -borderwidth 1
pack .fr.advanced -fill both -expand 0

##### Buttons section #####

# Define the buttons to submit the information or close the program

ttk::button .fr.cb -text "Close" -command { exit 1 }
pack .fr.cb -padx 5 -pady 5 -side right 

ttk::button .fr.ok -text "Run" -command { onDone }
pack .fr.ok -side right

#### Manadatory argument section ######

# Define the text that will be the introduction to the window

label .fr.principal.intro_1 -text "Welcome to DL4MicEverywhere!"
place .fr.principal.intro_1 -relx 0.01 -rely 0.0

# Define the list with possible default notebooks

set notebookList "-"
append notebookList " " $argv

font create myFont -family Helvetica -size 10

label .fr.principal.notebook_label -text "List of default notebooks:"
place .fr.principal.notebook_label -relx 0.01 -rely [expr 0.2 / ( 2 - $advanced_options ) ]

ttk::combobox .fr.principal.notebooks -values $notebookList -textvariable simpleNotebook -state readonly
place .fr.principal.notebooks -relx 0.01 -rely [expr 0.28 / ( 2 - $advanced_options ) ]
bind .fr.principal.notebooks <<ComboboxSelected>> { parseYaml [%W get]}

text .fr.principal.notebook_description -width 55 -height 5 -borderwidth 1 -relief sunken
place .fr.principal.notebook_description -relx 0.35 -rely [expr 0.2 / ( 2 - $advanced_options ) ]

label .fr.principal.update_text -textvariable update -foreground orange -font myFont
place .fr.principal.update_text -relx 0.01 -rely [expr 0.37 / ( 2 - $advanced_options ) ]

set simpleNotebook "-"


# Define the button and display to load the path to the data folder


label .fr.principal.data_label -text "Path to the data folder:"
place .fr.principal.data_label -relx 0.01 -rely [expr 0.45 / ( 2 - $advanced_options ) ]

entry .fr.principal.data_entry -textvariable data_path -width 60
place .fr.principal.data_entry -relx 0.01 -rely [expr 0.52 / ( 2 - $advanced_options ) ]

button .fr.principal.data_btn -text "Select" \
        -command "onSelectData"
place .fr.principal.data_btn -relx 0.87 -rely [expr 0.515 / ( 2 - $advanced_options ) ]

set data_path ""

# Define the button and display to load the path to the result folder

label .fr.principal.result_label -text "Path to the result/output folder:"
place .fr.principal.result_label -relx 0.01 -rely [expr 0.6 / ( 2 - $advanced_options ) ]

entry .fr.principal.result_entry -textvariable result_path -width 60
place .fr.principal.result_entry -relx 0.01 -rely [expr 0.67 / ( 2 - $advanced_options ) ]

button .fr.principal.result_btn -text "Select" \
        -command "onSelectResult"
place .fr.principal.result_btn -relx 0.87 -rely [expr 0.665 / ( 2 - $advanced_options ) ]

set result_path ""

##### Advanced arguments section #####

button .fr.principal.advanced -text "Advanced options" \
        -command "onAdvanced"
place .fr.principal.advanced -relx 0.01 -rely 0.93

# Define the button and display to load the path to the 'configuration.yaml' file

label .fr.advanced.yaml_label -text "Path to the configuration.yaml:"
place .fr.advanced.yaml_label -relx 0.01 -rely 0.2

entry .fr.advanced.yaml_entry -textvariable yaml_path -width 60
place .fr.advanced.yaml_entry -relx 0.01 -rely 0.27

button .fr.advanced.byp -text "Select" \
        -command "onSelectYaml"
place .fr.advanced.byp -relx 0.87 -rely 0.265

set yaml_path ""

# Define the button and display to load the path to the local notebook

label .fr.advanced.ipynb_label -text "Path to the local notebook:"
place .fr.advanced.ipynb_label -relx 0.01 -rely 0.35

entry .fr.advanced.ipynb_entry -textvariable ipynb_path -width 60
place .fr.advanced.ipynb_entry -relx 0.01 -rely 0.42

button .fr.advanced.bnp -text "Select" \
        -command "onSelectIpynb"
place .fr.advanced.bnp -relx 0.87 -rely 0.415

set ipynb_path ""

# Define the button and display to load the path to the data folder

label .fr.advanced.txt_label -text "Path to the requirements.txt:"
place .fr.advanced.txt_label -relx 0.01 -rely 0.50

entry .fr.advanced.txt_entry -textvariable txt_path -width 60
place .fr.advanced.txt_entry -relx 0.01 -rely 0.57

button .fr.advanced.btp -text "Select" \
        -command "onSelectTxt"
place .fr.advanced.btp -relx 0.87 -rely 0.565

set txt_path ""

# Define the checkbutton for the GPU usage

checkbutton .fr.advanced.gpu -text "Allow GPU" -variable gpu
place .fr.advanced.gpu -relx 0.1 -rely 0.71

# Define the docker tag text entry

label .fr.advanced.tag_label -text "Docker tag:"
place .fr.advanced.tag_label -relx 0.3 -rely 0.71

entry .fr.advanced.tag -textvariable tag -width 30
place .fr.advanced.tag -relx 0.425 -rely 0.705 

set tag ""

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "DL4MicEverywhere"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}