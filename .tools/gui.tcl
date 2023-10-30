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
                global selectedFolder
                global selectedNotebook
                if {"$selectedNotebook" == "-"} {
                    tk_messageBox -type ok -icon error -title Error \
                    -message "SIMPLE MODE: You need to specify a notebook."
                } else {
                    puts "$advanced_options"
                    puts "$data_path"
                    puts "$result_path"
                    puts "$selectedFolder"
                    puts "$selectedNotebook"
                    
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

    place .fr.principal.intro_2 -relx 0.01 -rely [expr 0.06 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_3 -relx 0.01 -rely [expr 0.12 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_4 -relx 0.01 -rely [expr 0.18 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_5 -relx 0.01 -rely [expr 0.24 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_6 -relx 0.01 -rely [expr 0.30 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_7 -relx 0.01 -rely [expr 0.36 / ( 2 - $advanced_options ) ]

    place .fr.principal.notebook_label -relx 0.01 -rely [expr 0.45 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebooks_folders -relx 0.01 -rely [expr 0.51 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebooks -relx 0.01 -rely [expr 0.59 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebook_description -relx 0.35 -rely [expr 0.45 / ( 2 - $advanced_options ) ]

    place .fr.principal.data_label -relx 0.01 -rely [expr 0.67 / ( 2 - $advanced_options ) ]
    place .fr.principal.data_entry -relx 0.01 -rely [expr 0.74 / ( 2 - $advanced_options ) ]
    place .fr.principal.data_btn -relx 0.87 -rely [expr 0.735 / ( 2 - $advanced_options ) ]

    place .fr.principal.result_label -relx 0.01 -rely [expr 0.83 / ( 2 - $advanced_options ) ]
    place .fr.principal.result_entry -relx 0.01 -rely [expr 0.89 / ( 2 - $advanced_options ) ]
    place .fr.principal.result_btn -relx 0.87 -rely [expr 0.885 / ( 2 - $advanced_options ) ]

}

proc onComboboxFolder {notebook_folder} {
    global selectedFolder
    global notebookList

    set selectedFolder "$notebook_folder"

    # Get notebooks on that folder
    catch {exec ls ./notebooks/$selectedFolder} output

    set notebookList "-"
    append notebookList " " $output

    .fr.principal.notebooks configure -values $notebookList
}

proc parseYaml {notebook_name} {
    global selectedFolder

    # Read a yaml file
    catch {exec /bin/bash .tools/parse_yaml.sh "$selectedFolder/$notebook_name"} output

    set arguments [split $output \n]

    # Get the arguments that we want
    .fr.principal.notebook_description delete 0.0 end

    if {[lindex $arguments 0] == 1} {
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "There is an updated version of this notebook.\n\n" highlight
    }
    .fr.principal.notebook_description insert end [lindex $arguments 1]

}


# The flag that indicates if "Advanced options" will be used
set advanced_options 0

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

ttk::button .fr.advance -text "Advanced options" -command { onAdvanced }
pack .fr.advance -padx 5 -side left 

#### Manadatory argument section ######

# Define the text that will be the introduction to the window

label .fr.principal.intro_1 -text "Welcome to DL4MicEverywhere!"
place .fr.principal.intro_1 -relx 0.01 -rely 0.0
label .fr.principal.intro_2 -text "DL4MicEverywhere allows you to build and run a Docker image for the ZeroCostDL4Mic notebooks."
place .fr.principal.intro_2 -relx 0.01 -rely [expr 0.06 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_3 -text "There are basic and advanced options."
place .fr.principal.intro_3 -relx 0.01 -rely [expr 0.12 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_4 -text "In the basic options, you only need to select three parameters:"
place .fr.principal.intro_4 -relx 0.01 -rely [expr 0.18 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_5 -text "    - A notebook from the given list, it will be the one loaded on the Docker container."
place .fr.principal.intro_5 -relx 0.01 -rely [expr 0.24 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_6 -text "    - The path to the folder containing the data you want to use in the notebook."
place .fr.principal.intro_6 -relx 0.01 -rely [expr 0.30 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_7 -text "    - The path to the folder where you want to store the results of the notebook."
place .fr.principal.intro_7 -relx 0.01 -rely [expr 0.36 / ( 2 - $advanced_options ) ]

# Define the list with possible default notebooks

set folderList "-"
append folderList " " $argv
set selectedFolder "-"

set notebookList "-"
set selectedNotebook "-"

font create myFont -family Helvetica -size 10

label .fr.principal.notebook_label -text "List of default notebooks:"
place .fr.principal.notebook_label -relx 0.01 -rely [expr 0.45 / ( 2 - $advanced_options ) ]

ttk::combobox .fr.principal.notebooks_folders -values $folderList -textvariable selectedFolder -state readonly
place .fr.principal.notebooks_folders -relx 0.01 -rely [expr 0.51 / ( 2 - $advanced_options ) ]
bind .fr.principal.notebooks_folders <<ComboboxSelected>> { onComboboxFolder [%W get]}

ttk::combobox .fr.principal.notebooks -values $notebookList -textvariable selectedNotebook -state readonly
place .fr.principal.notebooks -relx 0.01 -rely [expr 0.59 / ( 2 - $advanced_options ) ]
bind .fr.principal.notebooks <<ComboboxSelected>> { parseYaml [%W get]}

text .fr.principal.notebook_description -width 55 -height 5 -borderwidth 1 -relief sunken
place .fr.principal.notebook_description -relx 0.35 -rely [expr 0.45 / ( 2 - $advanced_options ) ]

# Define the button and display to load the path to the data folder


label .fr.principal.data_label -text "Path to the data folder:"
place .fr.principal.data_label -relx 0.01 -rely [expr 0.67 / ( 2 - $advanced_options ) ]

entry .fr.principal.data_entry -textvariable data_path -width 60
place .fr.principal.data_entry -relx 0.01 -rely [expr 0.74 / ( 2 - $advanced_options ) ]

button .fr.principal.data_btn -text "Select" \
        -command "onSelectData"
place .fr.principal.data_btn -relx 0.87 -rely [expr 0.735 / ( 2 - $advanced_options ) ]

set data_path ""

# Define the button and display to load the path to the result folder

label .fr.principal.result_label -text "Path to the result/output folder:"
place .fr.principal.result_label -relx 0.01 -rely [expr 0.83 / ( 2 - $advanced_options ) ]

entry .fr.principal.result_entry -textvariable result_path -width 60
place .fr.principal.result_entry -relx 0.01 -rely [expr 0.89 / ( 2 - $advanced_options ) ]

button .fr.principal.result_btn -text "Select" \
        -command "onSelectResult"
place .fr.principal.result_btn -relx 0.87 -rely [expr 0.885 / ( 2 - $advanced_options ) ]

set result_path ""

##### Advanced arguments section #####

# Define the text of the advanced option

label .fr.advanced.intro_1 -text "In the advanced options you can provide:"
place .fr.advanced.intro_1 -relx 0.01 -rely 0.0
label .fr.advanced.intro_2 -text "    - The path to a local 'configuration.yaml' file with the info to build a Docker container image."
place .fr.advanced.intro_2 -relx 0.01 -rely 0.06
label .fr.advanced.intro_3 -text "    - The path to a local notebook file that will be loaded in the Docker container."
place .fr.advanced.intro_3 -relx 0.01 -rely 0.12
label .fr.advanced.intro_4 -text "    - The path to the local requirements.txt file used to setup the Docker container image."
place .fr.advanced.intro_4 -relx 0.01 -rely 0.18
label .fr.advanced.intro_5 -text "    - Checkbox to setup a GPU-enabled Docker container image. A GPU has to be properly installed to be able to use it."
place .fr.advanced.intro_5 -relx 0.01 -rely 0.24
label .fr.advanced.intro_6 -text "    - The tag to name the generated Docker image."
place .fr.advanced.intro_6 -relx 0.01 -rely 0.30

# Define the button and display to load the path to the 'configuration.yaml' file

label .fr.advanced.yaml_label -text "Path to the configuration.yaml:"
place .fr.advanced.yaml_label -relx 0.01 -rely 0.37

entry .fr.advanced.yaml_entry -textvariable yaml_path -width 60
place .fr.advanced.yaml_entry -relx 0.01 -rely 0.44

button .fr.advanced.byp -text "Select" \
        -command "onSelectYaml"
place .fr.advanced.byp -relx 0.87 -rely 0.435

set yaml_path ""

# Define the button and display to load the path to the local notebook

label .fr.advanced.ipynb_label -text "Path to the local notebook:"
place .fr.advanced.ipynb_label -relx 0.01 -rely 0.52

entry .fr.advanced.ipynb_entry -textvariable ipynb_path -width 60
place .fr.advanced.ipynb_entry -relx 0.01 -rely 0.59

button .fr.advanced.bnp -text "Select" \
        -command "onSelectIpynb"
place .fr.advanced.bnp -relx 0.87 -rely 0.585

set ipynb_path ""

# Define the button and display to load the path to the data folder

label .fr.advanced.txt_label -text "Path to the requirements.txt:"
place .fr.advanced.txt_label -relx 0.01 -rely 0.67

entry .fr.advanced.txt_entry -textvariable txt_path -width 60
place .fr.advanced.txt_entry -relx 0.01 -rely 0.74

button .fr.advanced.btp -text "Select" \
        -command "onSelectTxt"
place .fr.advanced.btp -relx 0.87 -rely 0.735

set txt_path ""

# Define the checkbutton for the GPU usage

checkbutton .fr.advanced.gpu -text "Allow GPU" -variable gpu
place .fr.advanced.gpu -relx 0.1 -rely 0.87

# Define the docker tag text entry

label .fr.advanced.tag_label -text "Docker tag:"
place .fr.advanced.tag_label -relx 0.3 -rely 0.87

entry .fr.advanced.tag -textvariable tag -width 30
place .fr.advanced.tag -relx 0.425 -rely 0.865 

set tag ""

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "DL4MicEverywhere"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
