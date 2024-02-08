#! /usr/local/bin/wish

# Set the BASEDIR
set basedir [lindex $argv 0]

# Check if there is cache information
set filename "$basedir/.tools/.cache_gui"
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
    set cache_data_path ""
    set cache_result_path ""
    set cache_selected_folder ""
    set cache_selected_notebook ""
    set cache_config_path ""
    set cache_notebook_path ""
    set cache_requirements_path ""
    set cache_gpu_flag ""
    set cache_tag ""
}

# Define the shape of the window
set width 600
set height 750
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheigh .] - $height ) / 2 }]

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

proc onLoadCache {} {
    # Cached information
    global cache_data_path
    global cache_result_path
    global cache_selected_folder
    global cache_selected_notebook
    global cache_config_path
    global cache_notebook_path
    global cache_requirements_path
    global cache_gpu_flag
    global cache_tag

    # Variables from the widgets
    global data_path
    global result_path
    global selectedFolder
    global selectedNotebook
    global yaml_path
    global ipynb_path
    global txt_path
    global gpu
    global tag

    if  {"$cache_data_path" != ""} {
        set data_path "$cache_data_path"
    }
    if  {"$cache_result_path" != ""} {
        set result_path "$cache_result_path"
    }
    if  {"$cache_selected_folder" != ""} {
        set selectedFolder "$cache_selected_folder"
    }
    if  {"$cache_selected_notebook" != ""} {
        set selectedNotebook "$cache_selected_notebook"
    }
    if  {"$cache_config_path" != ""} {
        set yaml_path "$cache_config_path"
    }
    if  {"$cache_notebook_path" != ""} {
        set ipynb_path "$cache_notebook_path"
    }
    if  {"$cache_requirements_path" != ""} {
        set txt_path "$cache_requirements_path"
    }
    if  {"$cache_gpu_flag" != ""} {
        set gpu "$cache_gpu_flag"
    }
    if  {"$cache_tag" != ""} {
        set tag "$cache_tag"
    }
    
    # Update the information in the description box
    if {"$selectedNotebook" != "-"} {
        parseYaml $selectedNotebook
    }

}

proc onDone {} {
    global data_path
    global result_path
    global gpu
    global tag

    if {"$data_path" == ""} {
        tk_messageBox -type ok -icon error -title Error \
        -message "You need to specify a data folder."
    } else {
        if {"$result_path" == ""} {
            tk_messageBox -type ok -icon error -title Error \
            -message "You need to specify a result folder."
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
                    puts "$gpu"
                    puts "$tag"
                    
                    exit 0
                }
            } else {
                # The user has selected the advanced mode
                global yaml_path
                global ipynb_path
                global txt_path
                
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
                        set tag "-"
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
    global is_mac

    if {"$advanced_options" == 0} {
        set advanced_options 1
        pack .fr.advanced -fill both -expand 1 
        
        .fr.principal.notebooks configure -state disable
        .fr.principal.notebooks_folders configure -state disable

        place .fr.principal.notebooks_folders -relx 0.02 -rely [expr 0.55 / ( 2 - $advanced_options ) ]
        place .fr.principal.notebooks -relx 0.02 -rely [expr 0.55 / ( 2 - $advanced_options ) ]

        place .fr.principal.data_label -relx 0.02 -rely [expr 0.63 / ( 2 - $advanced_options ) ]
        place .fr.principal.data_entry -relx 0.02 -rely [expr 0.69 / ( 2 - $advanced_options ) ]
        place .fr.principal.data_btn -relx 0.85 -rely [expr 0.685 / ( 2 - $advanced_options ) ]

        place .fr.principal.result_label -relx 0.02 -rely [expr 0.76 / ( 2 - $advanced_options ) ]
        place .fr.principal.result_entry -relx 0.02 -rely [expr 0.82 / ( 2 - $advanced_options ) ]
        place .fr.principal.result_btn -relx 0.85 -rely [expr 0.825 / ( 2 - $advanced_options ) ]

        place .fr.principal.gpu -relx 0.15 -rely [expr 0.91 / ( 2 - $advanced_options ) ]
        place .fr.principal.cache_btn -relx 0.6 -rely [expr 0.91 / ( 2 - $advanced_options ) ]

        .fr.principal.notebook_description configure -height [expr 1 + ($is_mac * 2)] 
        .fr.principal.notebook_description delete 0.0 end
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "On advanced mode, default notebooks are disabled." highlight

    } else {
        set advanced_options 0
        pack .fr.advanced -fill both -expand 0
        
        .fr.principal.notebooks configure -state normal
        .fr.principal.notebooks_folders configure -state normal

        place .fr.principal.notebooks_folders -relx 0.02 -rely [expr 0.55 / ( 2 - $advanced_options ) ]
        place .fr.principal.notebooks -relx 0.02 -rely [expr 0.63 / ( 2 - $advanced_options ) ]

        place .fr.principal.data_label -relx 0.02 -rely [expr 0.71 / ( 2 - $advanced_options ) ]
        place .fr.principal.data_entry -relx 0.02 -rely [expr 0.77 / ( 2 - $advanced_options ) ]
        place .fr.principal.data_btn -relx 0.85 -rely [expr 0.765 / ( 2 - $advanced_options ) ]

        place .fr.principal.result_label -relx 0.02 -rely [expr 0.85 / ( 2 - $advanced_options ) ]
        place .fr.principal.result_entry -relx 0.02 -rely [expr 0.91 / ( 2 - $advanced_options ) ]
        place .fr.principal.result_btn -relx 0.85 -rely [expr 0.915 / ( 2 - $advanced_options ) ]

        place .fr.principal.gpu -relx 0.15 -rely [expr 0.999 / ( 2 - $advanced_options ) ]
        place .fr.principal.cache_btn -relx 0.6 -rely [expr 0.999 / ( 2 - $advanced_options ) ]

        .fr.principal.notebook_description configure -height [expr 4 + ($is_mac * 2)] 
        .fr.principal.notebook_description delete 0.0 end
        global selectedNotebook
        if {"$selectedNotebook" != "-"} {
            parseYaml $selectedNotebook
        }
    }

    place .fr.principal.intro_2 -relx 0.02 -rely [expr 0.06 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_3 -relx 0.02 -rely [expr 0.12 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_4 -relx 0.02 -rely [expr 0.18 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_5 -relx 0.02 -rely [expr 0.24 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_6 -relx 0.02 -rely [expr 0.30 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_7 -relx 0.02 -rely [expr 0.36 / ( 2 - $advanced_options ) ]
    place .fr.principal.intro_8 -relx 0.02 -rely [expr 0.42 / ( 2 - $advanced_options ) ]

    place .fr.principal.notebook_label -relx 0.02 -rely [expr 0.49 / ( 2 - $advanced_options ) ]
    place .fr.principal.notebook_description -relx 0.375 -rely [expr 0.495 / ( 2 - $advanced_options ) ]

}

proc onComboboxFolder {notebook_folder} {
    global basedir

    global selectedFolder
    global selectedNotebook
    global notebookList

    # Reset selected notebook
    set selectedNotebook "-"
    
    # Always update the selected folder
    set selectedFolder ${notebook_folder}

    # Reset the notebook list
    set notebookList "-"
    # Get notebooks on that folder
    if {"$selectedFolder" != "-"} {
        
        # Get the number of subfolders in the selected folder
        catch {eval exec ls -1 -d [glob -nocomplain "$basedir/notebooks/$selectedFolder/*/"] | wc -l} num_folders
        
        set no_folders 0
        if {"$num_folders" == 1} {
            # In case only one folder has been found, it may be that there are no folder
            catch {eval exec ls -1 -d [glob -nocomplain "$basedir/notebooks/$selectedFolder/*/"]} folder_name
            if {"$folder_name" == "."} {
                # If the folder is called ".", this means that there are no folders
                set no_folders 1
            }
        }

        if {"$no_folders" != 1} {
            # Notebook list will only be updated in case there are subfolders
            catch {eval exec ls -d [glob "$basedir/notebooks/$selectedFolder/*/"] | xargs basename -a} output
            append notebookList " " $output
        }
    
    } else {
        set selectedNotebook "-"
    }

    .fr.principal.notebooks configure -values $notebookList
}

proc parseYaml {notebook_name} {
    global basedir
    global selectedFolder

    # Read a yaml file
    catch {exec /bin/bash $basedir/.tools/bash_tools/parse_yaml.sh "$basedir" "$selectedFolder" "$notebook_name"} output

    set arguments [split $output \n]

    # Get the arguments that we want
    .fr.principal.notebook_description delete 0.0 end

    if {[lindex $arguments 0] == 1} {
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "There is an updated version of this notebook.\n\n" highlight
    }
    if {[lindex $arguments 1] == 1} {
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "There is an updated version of DL4MicEverywhere.\n\n" highlight
    }
    if {[lindex $arguments 1] == 2} {
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "Local configuration file does not have dl4miceverywhere version.\n\n" highlight
    }
    if {[lindex $arguments 1] == 3} {
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "Online configuration file does not have dl4miceverywhere version.\n\n" highlight
    }
    .fr.principal.notebook_description insert end [lindex $arguments 2]

}

# The flag that indicates if "Advanced options" will be used
set advanced_options 0

# Read the OS of the computer
set operative_system [lindex $argv 1]
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
image create photo img1 -file ${basedir}/docs/logo/dl4miceverywhere-logo-small.png
label .fr.principal.logo -image img1
place .fr.principal.logo -x 450 -y 5

# Define the text that will be the introduction to the window

label .fr.principal.intro_1 -text "Welcome to DL4MicEverywhere!"
place .fr.principal.intro_1 -relx 0.02 -rely 0.0
label .fr.principal.intro_2 -text "Providing an easy way to apply deep learning to microscopy"
place .fr.principal.intro_2 -relx 0.02 -rely [expr 0.06 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_3 -text "using interactive Jupyter notebooks."
place .fr.principal.intro_3 -relx 0.02 -rely [expr 0.12 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_4 -text "To get started, specify:"
place .fr.principal.intro_4 -relx 0.02 -rely [expr 0.18 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_5 -text "    - Notebook: Select from the available deep learning workflows"
place .fr.principal.intro_5 -relx 0.02 -rely [expr 0.24 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_6 -text "    - Data folder: Location of your input microscopy images"
place .fr.principal.intro_6 -relx 0.02 -rely [expr 0.30 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_7 -text "    - Output folder: Where to save your results"
place .fr.principal.intro_7 -relx 0.02 -rely [expr 0.36 / ( 2 - $advanced_options ) ]
label .fr.principal.intro_8 -text "    - Checkbox for setting up a GPU-enabled Docker container image"
place .fr.principal.intro_8 -relx 0.02 -rely [expr 0.42 / ( 2 - $advanced_options ) ]

# Define the list with possible default notebooks

set folderList "-"

# Get the number of folders
catch {eval exec ls -1 -d [glob -nocomplain "$basedir/notebooks/*/"] | wc -l} num_folders

set no_folders 0
if {"$num_folders" != 1} {
    # In case only one folder has been found, it may be that there are no folder
    catch {eval exec ls -1 -d [glob -nocomplain "$basedir/notebooks/*/"]} folder_name
    if {"$folder_name" == "."} {
        # If the folder is called ".", this means that there are no folders
        set no_folders 1
    }
}

if {"$no_folders" != 1} {
    # In case no folders are found 
    catch {eval exec ls -d [glob "$basedir/notebooks/*/"] | xargs basename -a} aux_notebok_folder_list
    append folderList " " $aux_notebok_folder_list
}

set selectedFolder "-"

set notebookList "-"
set selectedNotebook "-"

font create myFont -family Helvetica -size 10

label .fr.principal.notebook_label -text "List of default notebooks:"
place .fr.principal.notebook_label -relx 0.02 -rely [expr 0.49 / ( 2 - $advanced_options ) ]

ttk::combobox .fr.principal.notebooks_folders -values $folderList -textvariable selectedFolder -state readonly
place .fr.principal.notebooks_folders -relx 0.02 -rely [expr 0.55 / ( 2 - $advanced_options ) ]
bind .fr.principal.notebooks_folders <<ComboboxSelected>> { onComboboxFolder [%W get]}

ttk::combobox .fr.principal.notebooks -values $notebookList -textvariable selectedNotebook -state readonly
place .fr.principal.notebooks -relx 0.02 -rely [expr 0.63 / ( 2 - $advanced_options ) ]
bind .fr.principal.notebooks <<ComboboxSelected>> { parseYaml [%W get]}

text .fr.principal.notebook_description -width [expr 35 + ($is_mac * 15) + ($is_linux * 10) ] -height [expr 4 + ($is_mac * 2)] -borderwidth 1 -relief sunken
place .fr.principal.notebook_description -relx 0.375 -rely [expr 0.495 / ( 2 - $advanced_options ) ]

# Define the button and display to load the path to the data folder


label .fr.principal.data_label -text "Path to data folder:"
place .fr.principal.data_label -relx 0.02 -rely [expr 0.71 / ( 2 - $advanced_options ) ]

entry .fr.principal.data_entry -textvariable data_path -width [expr 58 + ($is_mac * -5) + ($is_linux * 2)]
place .fr.principal.data_entry -relx 0.02 -rely [expr 0.77 / ( 2 - $advanced_options ) ]

button .fr.principal.data_btn -text "Select" \
        -command "onSelectData"
place .fr.principal.data_btn -relx 0.85 -rely [expr 0.765 / ( 2 - $advanced_options ) ]

set data_path ""

# Define the button and display to load the path to the result folder

label .fr.principal.result_label -text "Path to output folder:"
place .fr.principal.result_label -relx 0.02 -rely [expr 0.85 / ( 2 - $advanced_options ) ]

entry .fr.principal.result_entry -textvariable result_path -width [expr 58 + ($is_mac * -5) + ($is_linux * 2)]
place .fr.principal.result_entry -relx 0.02 -rely [expr 0.91 / ( 2 - $advanced_options ) ]

button .fr.principal.result_btn -text "Select" \
        -command "onSelectResult"
place .fr.principal.result_btn -relx 0.85 -rely [expr 0.915 / ( 2 - $advanced_options ) ]

set result_path ""

# Define the checkbutton for the GPU usage

checkbutton .fr.principal.gpu -text "Allow GPU" -variable gpu
place .fr.principal.gpu -relx 0.15 -rely [expr 0.999 / ( 2 - $advanced_options ) ]

# Disable the GPU option in case 'nvidia-smi' command is not found
if { [catch { exec nvidia-smi } msg] } {
    .fr.principal.gpu configure -state disable
}


# Define a button to load cached data if there is so

button .fr.principal.cache_btn -text "Load previous settings" \
        -command "onLoadCache"
place .fr.principal.cache_btn -relx 0.55 -rely [expr 0.999 / ( 2 - $advanced_options ) ]

# Disable the cache if no cache file is found
if {"$fexist" == "0"} {
    .fr.principal.cache_btn configure -state disable
}

##### Advanced arguments section #####

# Define the text of the advanced option

label .fr.advanced.intro_1 -text "Advanced options allow you to specify:"
place .fr.advanced.intro_1 -relx 0.02 -rely 0.0
label .fr.advanced.intro_2 -text "    - Path to a local 'configuration.yaml' file for Docker container image construction"
place .fr.advanced.intro_2 -relx 0.02 -rely 0.06
label .fr.advanced.intro_3 -text "    - Path to a local notebook file to be loaded into the Docker container"
place .fr.advanced.intro_3 -relx 0.02 -rely 0.12
label .fr.advanced.intro_4 -text "    - Path to the local 'requirements.txt' file for Docker container image setup"
place .fr.advanced.intro_4 -relx 0.02 -rely 0.18
label .fr.advanced.intro_6 -text "    - Tag for naming the generated Docker image"
place .fr.advanced.intro_6 -relx 0.02 -rely 0.24

# Define the button and display to load the path to the 'configuration.yaml' file

label .fr.advanced.yaml_label -text "Path to the configuration.yaml:"
place .fr.advanced.yaml_label -relx 0.02 -rely 0.32

entry .fr.advanced.yaml_entry -textvariable yaml_path -width [expr 58 + ($is_mac * -5) + ($is_linux * 2)]
place .fr.advanced.yaml_entry -relx 0.02 -rely 0.39

button .fr.advanced.byp -text "Select" \
        -command "onSelectYaml"
place .fr.advanced.byp -relx 0.85 -rely 0.385

set yaml_path ""

# Define the button and display to load the path to the local notebook

label .fr.advanced.ipynb_label -text "Path to the local notebook:"
place .fr.advanced.ipynb_label -relx 0.02 -rely 0.47

entry .fr.advanced.ipynb_entry -textvariable ipynb_path -width [expr 58 + ($is_mac * -5) + ($is_linux * 2)]
place .fr.advanced.ipynb_entry -relx 0.02 -rely 0.54

button .fr.advanced.bnp -text "Select" \
        -command "onSelectIpynb"
place .fr.advanced.bnp -relx 0.85 -rely 0.535

set ipynb_path ""

# Define the button and display to load the path to the data folder

label .fr.advanced.txt_label -text "Path to the requirements.txt:"
place .fr.advanced.txt_label -relx 0.02 -rely 0.62

entry .fr.advanced.txt_entry -textvariable txt_path -width [expr 58 + ($is_mac * -5) + ($is_linux * 2)]
place .fr.advanced.txt_entry -relx 0.02 -rely 0.69

button .fr.advanced.btp -text "Select" \
        -command "onSelectTxt"
place .fr.advanced.btp -relx 0.85 -rely 0.685

set txt_path ""

# Define the docker tag text entry

label .fr.advanced.tag_label -text "Docker tag:"
place .fr.advanced.tag_label -relx 0.02 -rely 0.77

entry .fr.advanced.tag -textvariable tag -width [expr 40  + ($is_linux * 2)]
place .fr.advanced.tag -relx 0.02 -rely 0.84

set tag ""

##### Create a window #####

# Create the window, give a name to it and locate it in the middle of the screen
wm title . "DL4MicEverywhere"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
