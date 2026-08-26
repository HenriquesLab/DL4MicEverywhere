#! /usr/local/bin/wish

# Set the BASEDIR
set basedir [lindex $argv 0]

# Check if there is cache information
set filename "$basedir/.tools/.cache/.cache_gui"
set fexist [file exist $filename]

# Initialize the cache variables
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
    set cache_flag_gpu ""
    set cache_selected_version ""
    set cache_tag ""
    set cache_advanced_options ""
}

# Check if the construct.yaml file is accessible
set construct "$basedir/construct.yaml"
set construct_exist [file exist $construct]

# Get DL4MicEverywhere version if possible and define the window title
if {"$construct_exist" == "1"} {
    catch {exec /bin/bash "$basedir/.tools/bash_tools/get_dl4miceverywhere_version.sh"} output
    set window_title "DL4MicEverywhere - v$output"
} else {
    set window_title "DL4MicEverywhere"
}

# Define preferred and minimum window sizes. These are starting/layout hints only:
# the window and its contents remain fully resizable.
set preferred_width 720
set preferred_height 760
set minimum_width 600
set minimum_height 620

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
    global cache_flag_gpu
    global cache_selected_version
    global cache_tag
    global cache_advanced_options

    # Variables from the widgets
    global data_path
    global result_path
    global selectedFolder
    global selectedNotebook
    global yaml_path
    global ipynb_path
    global txt_path
    global gpu
    global selectedVersion
    global tag
    global advanced_options

    if  {"$cache_data_path" != ""} {
        set data_path "$cache_data_path"
    }
    if  {"$cache_result_path" != ""} {
        set result_path "$cache_result_path"
    }
    if  {"$cache_selected_folder" != ""} {
        set selectedFolder "$cache_selected_folder"
        onComboboxSelectedFolder "$cache_selected_folder"

        if  {"$cache_selected_notebook" != ""} {
            set selectedNotebook "$cache_selected_notebook"
            # Update the information in the description box
            onComboboxSelectedNotebook "$cache_selected_notebook"

            if  {"$cache_selected_version" != ""} {
                set selectedVersion "$cache_selected_version"
            }
        }
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
    if  {"$cache_flag_gpu" != ""} {
        set gpu "$cache_flag_gpu"
    }
    if  {"$cache_tag" != ""} {
        set tag "$cache_tag"
    }
    if  {"$cache_advanced_options" != ""} {
        set advanced_options "$cache_advanced_options"
    }

    # Open advanced opions in case it was like that
    if  {"$cache_advanced_options" == "1"} {
        # OnAdvanced is expecting that advanced_options is 0 so that it can open by itself
        # the advanced section and change its value to 1. 
        set advanced_options 0
        onAdvanced
    }
    

}

proc onDone {} {
    global data_path
    global result_path
    global gpu
    global selectedVersion
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
                    puts "$selectedVersion"
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
                    puts "$selectedVersion"
                    puts "$tag"
                    
                    exit 0
                }
            }
        }
    }
}

proc onAdvanced {} {
    global advanced_options
    global min_width
    global min_height

    if {"$advanced_options" == 0} {
        set advanced_options 1

        # Reveal the advanced section. Grid handles the vertical reflow, so no
        # widgets in the principal section need to be manually repositioned.
        grid .fr.advanced -row 1 -column 0 -columnspan 3 -sticky ew -padx 0 -pady 0

        .fr.principal.notebooks configure -state disabled
        .fr.principal.notebooks_folders configure -state disabled
        .fr.principal.versions configure -state disabled

        .fr.principal.notebook_description configure -state normal
        .fr.principal.notebook_description delete 1.0 end
        .fr.principal.notebook_description tag configure highlight -foreground DarkOrange2 -font {courier 12 bold}
        .fr.principal.notebook_description insert end "On advanced mode, default notebooks are disabled." highlight
        .fr.principal.notebook_description configure -state disabled

        # Advanced mode needs additional vertical room. Prevent controls from
        # being clipped by raising the minimum height up to the screen limit.
        update idletasks
        set screen_limit [expr {max(500, [winfo vrootheight .] - 80)}]
        set advanced_min_height [expr {min([winfo reqheight .fr], $screen_limit)}]
        wm minsize . $min_width $advanced_min_height
    } else {
        set advanced_options 0
        grid remove .fr.advanced
        wm minsize . $min_width $min_height

        # Comboboxes are selectors, not free-text fields. Restore readonly
        # rather than normal when leaving advanced mode.
        .fr.principal.notebooks configure -state readonly
        .fr.principal.notebooks_folders configure -state readonly
        .fr.principal.versions configure -state readonly

        .fr.principal.notebook_description configure -state normal
        .fr.principal.notebook_description delete 1.0 end
        global selectedNotebook
        if {"$selectedNotebook" != "-"} {
            onComboboxSelectedNotebook $selectedNotebook
        }
    }
}

proc onComboboxSelectedFolder {notebook_folder} {
    global basedir

    global selectedFolder
    global notebookList
    global selectedNotebook

    # Variables to update the version of the notebook 
    global versionList
    global selectedVersion

    # Reset selected notebook and version
    set selectedNotebook "-"
    set selectedVersion "-"
    
    # Always update the selected folder
    set selectedFolder "${notebook_folder}"

    # Reset the notebook list and version list
    set notebookList "-"
    set versionList "-"

    # Get notebooks on that folder
    if {"$selectedFolder" != "-"} {
        
        # Get the number of subfolders in the selected folder

        catch {eval exec find [glob "$basedir/notebooks/$selectedFolder/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0 | wc -l} num_folders
        
        set no_folders_flag 0
        if {"$num_folders" == 1} {
            # In case only one folder has been found, it may be that there are no folder
            catch {eval exec find [glob "$basedir/notebooks/$selectedFolder/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0} folder_name

            if {"$folder_name" == "."} {
                # If the folder is called ".", this means that there are no folders
                set no_folders_flag 1
            }
        }

        if {"$no_folders_flag" != 1} {
            # Notebook list will only be updated in case there are subfolders
            catch {eval exec find [glob "$basedir/notebooks/$selectedFolder/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0 | xargs -0 -n 1 basename | sort} output

            append notebookList " " $output
        }
    
    } else {
        set selectedNotebook "-"
    }

    .fr.principal.notebooks configure -values $notebookList
    .fr.principal.versions configure -values $versionList
}

proc onComboboxSelectedNotebook {notebook_name} {
    global basedir
    global selectedFolder

    # Variables to update the version of the notebook 
    global selectedVersion
    global versionList

    # If a notebook has been selected
    if {"$notebook_name" != "-"} {

        # Reset selected version to latest and version list
        set selectedVersion "-"

        # Reset the version list
        set versionList "-"
        
        # Read a yaml file
        catch {exec /bin/bash "$basedir/.tools/bash_tools/get_local_description.sh" "$basedir" "$selectedFolder" "$notebook_name"} output
        set arguments [split "$output" \n]

        # Get the arguments that we want
        .fr.principal.notebook_description delete 0.0 end
        .fr.principal.notebook_description insert end [lindex "$arguments" 0]

        # Get the list with the versions
        catch {exec /bin/bash "$basedir/.tools/bash_tools/get_docker_versions.sh" "$notebook_name"} version_list
        append versionList " " "$version_list"
    } else {
        set selectedVersion "-"
        set versionList "-"
    }

    .fr.principal.versions configure -values $versionList
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

# Use grid for the main layout so controls follow the available window size.
# Principal content grows with the window; the advanced section is inserted
# between it and the action buttons when requested.
frame .fr

grid .fr -row 0 -column 0 -sticky nsew
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

grid columnconfigure .fr 0 -weight 1
grid columnconfigure .fr 1 -weight 0
grid columnconfigure .fr 2 -weight 0
grid rowconfigure .fr 0 -weight 1

frame .fr.principal -relief raised -borderwidth 1
grid .fr.principal -row 0 -column 0 -columnspan 3 -sticky nsew

# The first two columns receive extra horizontal space. The last column is
# reserved for buttons and stays at its natural width.
grid columnconfigure .fr.principal 0 -weight 1
# Give the description area more of the extra horizontal space.
grid columnconfigure .fr.principal 1 -weight 2
grid columnconfigure .fr.principal 2 -weight 0
# Extra vertical space is assigned to the notebook/description area.
grid rowconfigure .fr.principal 11 -weight 1

frame .fr.advanced -relief raised -borderwidth 1
grid columnconfigure .fr.advanced 0 -weight 1
grid columnconfigure .fr.advanced 1 -weight 0

##### Buttons section #####

# Define the buttons to submit the information or close the program.
ttk::button .fr.advance -text "Advanced options" -command { onAdvanced }
grid .fr.advance -row 2 -column 0 -sticky w -padx 8 -pady 8

ttk::button .fr.ok -text "Run" -command { onDone }
grid .fr.ok -row 2 -column 1 -sticky e -padx 5 -pady 8

ttk::button .fr.cb -text "Close" -command { exit 1 }
grid .fr.cb -row 2 -column 2 -sticky e -padx {0 8} -pady 8

#### Mandatory argument section ######

image create photo img1 -file "${basedir}/docs/logo/dl4miceverywhere-logo-small.png"
label .fr.principal.logo -image img1
grid .fr.principal.logo -row 0 -column 2 -rowspan 4 -sticky ne -padx 12 -pady 8

# Define the text that will be the introduction to the window.
label .fr.principal.intro_1 -text "Welcome to DL4MicEverywhere!" -anchor w
grid .fr.principal.intro_1 -row 0 -column 0 -columnspan 2 -sticky ew -padx 12 -pady {8 0}

label .fr.principal.intro_2 -text "Providing an easy way to apply deep learning to microscopy" -anchor w
grid .fr.principal.intro_2 -row 1 -column 0 -columnspan 2 -sticky ew -padx 12

label .fr.principal.intro_3 -text "using interactive Jupyter notebooks." -anchor w
grid .fr.principal.intro_3 -row 2 -column 0 -columnspan 2 -sticky ew -padx 12

label .fr.principal.intro_4 -text "To get started, specify:" -anchor w
grid .fr.principal.intro_4 -row 3 -column 0 -columnspan 2 -sticky ew -padx 12 -pady {4 0}

label .fr.principal.intro_5 -text "    - Notebook: Select from the available deep learning workflows" -anchor w
grid .fr.principal.intro_5 -row 4 -column 0 -columnspan 3 -sticky ew -padx 12

label .fr.principal.intro_6 -text "    - Data folder: Location of your input microscopy images" -anchor w
grid .fr.principal.intro_6 -row 5 -column 0 -columnspan 3 -sticky ew -padx 12

label .fr.principal.intro_7 -text "    - Output folder: Where to save your results" -anchor w
grid .fr.principal.intro_7 -row 6 -column 0 -columnspan 3 -sticky ew -padx 12

label .fr.principal.intro_8 -text "    - Checkbox for setting up a GPU-enabled Docker container image" -anchor w
grid .fr.principal.intro_8 -row 7 -column 0 -columnspan 3 -sticky ew -padx 12 -pady {0 8}

# Define the list with possible default notebooks.
set folderList "-"

# Get the number of folders.
catch {eval exec find [glob "$basedir/notebooks/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0 | wc -l} num_folders

# Flag to indicate if there are no folders.
set no_folders_flag 0

# Check the number of folders.
if {"$num_folders" == 0} {
    # If it is 0, then there are no folders.
    set no_folders_flag_flag 1
} else {
    # Otherwise, check the depth on the folders.
    catch {eval exec find [glob "$basedir/notebooks/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0} folder_name
    # Check if there are no subfolders.
    if {"$folder_name" == "."} {
        # If the folder_name is ".", this means that there are no subfolders on the notebooks folder.
        set no_folders_flag 1
    }
}

# In case there are subfolders (flag of NO folders is off).
if {"$no_folders_flag" == 0} {
    catch {eval exec find [glob "$basedir/notebooks/"] -mindepth 1 -maxdepth 1 -type d ! -name '.' -print0 | xargs -0 -n 1 basename | sort} aux_notebok_folder_list
    append folderList " " "$aux_notebok_folder_list"
}

set selectedFolder "-"
set notebookList "-"
set selectedNotebook "-"

font create myFont -family Helvetica -size 10

label .fr.principal.notebook_label -text "List of default notebooks:" -anchor w
grid .fr.principal.notebook_label -row 8 -column 0 -columnspan 3 -sticky ew -padx 12 -pady {4 3}

ttk::combobox .fr.principal.notebooks_folders -values $folderList -textvariable selectedFolder -state readonly
grid .fr.principal.notebooks_folders -row 9 -column 0 -sticky ew -padx {12 8} -pady 2
bind .fr.principal.notebooks_folders <<ComboboxSelected>> { onComboboxSelectedFolder [%W get]}

ttk::combobox .fr.principal.notebooks -values $notebookList -textvariable selectedNotebook -state readonly
grid .fr.principal.notebooks -row 10 -column 0 -sticky new -padx {12 8} -pady 2
bind .fr.principal.notebooks <<ComboboxSelected>> { onComboboxSelectedNotebook [%W get]}

# Width and height are initial requests only. sticky=nsew plus row/column weights
# make this widget grow and shrink with the window.
text .fr.principal.notebook_description -width 30 -height 4 -wrap word -borderwidth 1 -relief sunken
grid .fr.principal.notebook_description -row 9 -column 1 -rowspan 3 -columnspan 2 -sticky nsew -padx {8 12} -pady 2

# Define the button and display to load the path to the data folder.
label .fr.principal.data_label -text "Path to data folder:" -anchor w
grid .fr.principal.data_label -row 12 -column 0 -columnspan 3 -sticky ew -padx 12 -pady {8 2}

entry .fr.principal.data_entry -textvariable data_path
grid .fr.principal.data_entry -row 13 -column 0 -columnspan 2 -sticky ew -padx {12 6} -pady 2

button .fr.principal.data_btn -text "Select" -command "onSelectData"
grid .fr.principal.data_btn -row 13 -column 2 -sticky e -padx {6 12} -pady 2

set data_path ""

# Define the button and display to load the path to the result folder.
label .fr.principal.result_label -text "Path to output folder:" -anchor w
grid .fr.principal.result_label -row 14 -column 0 -columnspan 3 -sticky ew -padx 12 -pady {8 2}

entry .fr.principal.result_entry -textvariable result_path
grid .fr.principal.result_entry -row 15 -column 0 -columnspan 2 -sticky ew -padx {12 6} -pady 2

button .fr.principal.result_btn -text "Select" -command "onSelectResult"
grid .fr.principal.result_btn -row 15 -column 2 -sticky e -padx {6 12} -pady 2

set result_path ""

# Define the GPU, version and cache controls in a nested row. The middle
# spacer grows, keeping the cache button aligned to the right.
frame .fr.principal.options
grid .fr.principal.options -row 16 -column 0 -columnspan 3 -sticky ew -padx 8 -pady {8 6}
grid columnconfigure .fr.principal.options 1 -weight 1

set gpu 0
checkbutton .fr.principal.gpu -text "Allow GPU" -variable gpu
grid .fr.principal.gpu -in .fr.principal.options -row 0 -column 0 -sticky w -padx 4

# Disable the GPU option in case 'nvidia-smi' command is not found.
if { [catch { exec nvidia-smi } msg] } {
    .fr.principal.gpu configure -state disable
}

# Define the version number.
set versionList "-"
set selectedVersion "-"

label .fr.principal.version_label -text "Version:"
grid .fr.principal.version_label -in .fr.principal.options -row 0 -column 2 -sticky e -padx {8 4}

ttk::combobox .fr.principal.versions -values $versionList -textvariable selectedVersion -width 10 -state readonly
grid .fr.principal.versions -in .fr.principal.options -row 0 -column 3 -sticky e -padx 4

# Define a button to load cached data if there is so.
button .fr.principal.cache_btn -text "Load previous settings" -command "onLoadCache"
grid .fr.principal.cache_btn -in .fr.principal.options -row 0 -column 4 -sticky e -padx 4

# Disable the cache if no cache file is found.
if {"$fexist" == "0"} {
    .fr.principal.cache_btn configure -state disable
}

##### Advanced arguments section #####

# Keep the advanced form compact so opening it does not force the main form
# off screen. Labels stay at their natural size, file entries grow, and Select
# buttons stay fixed.
grid columnconfigure .fr.advanced 0 -weight 0
grid columnconfigure .fr.advanced 1 -weight 1
grid columnconfigure .fr.advanced 2 -weight 0

label .fr.advanced.intro_1 \
    -text "Advanced options: choose local files to override the default notebook configuration." \
    -anchor w
grid .fr.advanced.intro_1 -row 0 -column 0 -columnspan 3 -sticky ew -padx 12 -pady {8 6}

# configuration.yaml
label .fr.advanced.yaml_label -text "Configuration (.yaml):" -anchor w
grid .fr.advanced.yaml_label -row 1 -column 0 -sticky w -padx {12 6} -pady 3

entry .fr.advanced.yaml_entry -textvariable yaml_path
grid .fr.advanced.yaml_entry -row 1 -column 1 -sticky ew -padx 6 -pady 3

button .fr.advanced.byp -text "Select" -command "onSelectYaml"
grid .fr.advanced.byp -row 1 -column 2 -sticky e -padx {6 12} -pady 3

set yaml_path ""

# Optional local notebook.
label .fr.advanced.ipynb_label -text "Notebook (.ipynb):" -anchor w
grid .fr.advanced.ipynb_label -row 2 -column 0 -sticky w -padx {12 6} -pady 3

entry .fr.advanced.ipynb_entry -textvariable ipynb_path
grid .fr.advanced.ipynb_entry -row 2 -column 1 -sticky ew -padx 6 -pady 3

button .fr.advanced.bnp -text "Select" -command "onSelectIpynb"
grid .fr.advanced.bnp -row 2 -column 2 -sticky e -padx {6 12} -pady 3

set ipynb_path ""

# Optional requirements file.
label .fr.advanced.txt_label -text "Requirements (.txt):" -anchor w
grid .fr.advanced.txt_label -row 3 -column 0 -sticky w -padx {12 6} -pady 3

entry .fr.advanced.txt_entry -textvariable txt_path
grid .fr.advanced.txt_entry -row 3 -column 1 -sticky ew -padx 6 -pady 3

button .fr.advanced.btp -text "Select" -command "onSelectTxt"
grid .fr.advanced.btp -row 3 -column 2 -sticky e -padx {6 12} -pady 3

set txt_path ""

# Optional Docker image tag.
label .fr.advanced.tag_label -text "Docker tag:" -anchor w
grid .fr.advanced.tag_label -row 4 -column 0 -sticky w -padx {12 6} -pady {3 8}

entry .fr.advanced.tag -textvariable tag
grid .fr.advanced.tag -row 4 -column 1 -sticky ew -padx 6 -pady {3 8}

set tag ""

# The frame itself is intentionally not managed here. onAdvanced adds/removes
# it from .fr while grid automatically reflows the rest of the interface.

##### Create the menu #####

. config -menu .mb
menu .mb -type menubar

.mb add cascade -label DL4MicEverywhere -underline 0 -menu .mb.file
menu .mb.file -type normal -tearoff 0
.mb.file add command -label About -underline 0 -command { cmdabout } -accelerator Ctrl-i
.mb.file add command -label Preferences -underline 0 -command { cmdpref } -accelerator Ctrl-p
.mb.file add command -label "Check For Updates" -underline 0 -command { cmdpcheckupdates } -accelerator Ctrl-u
.mb.file add separator
.mb.file add command -label "Uninstall DL4MicEverywhere..." -command { cmduninstall }
.mb.file add separator
.mb.file add command -label Quit -underline 0 -command { exit } -accelerator Ctrl-x

bind .fr <Control-i> cmdabout
bind .fr <Control-p> cmdpref
bind .fr <Control-u> cmdpcheckupdates

.mb add cascade -label Help -underline 0 -menu .mb.edit
menu .mb.edit -type normal -tearoff 0
.mb.edit add command -label Documentation -underline 0 -command { cmddoc } -accelerator Ctrl-d

bind .fr <Control-d> cmddoc

proc cmdabout {} {
    global basedir
    exec wish "$basedir/.tools/tcl_tools/menubar/about.tcl" "$basedir"
}
proc cmdpref {}   {
    global basedir
    exec /bin/bash "$basedir/.tools/bash_tools/cache_preferences.sh"
}
proc cmdpcheckupdates {}   {
    global basedir
    # Call the update script update_dl4miceverywhere.sh with argument already_asked=1 (true)
    catch {exec /bin/bash "$basedir/.tools/bash_tools/pre_build_launch/update_dl4miceverywhere.sh" "1" "1" 2>@1} r
    # Check if an update has been made and close the window if so
    if {"$r" != ""} {
        exit 1
    }
}
proc cmduninstall {} {
    global basedir

    # The confirmation dialog returns:
    #   0 = cancel
    #   1 = uninstall application files only
    #   2 = uninstall application files and DL4MicEverywhere Docker resources
    if {[catch {exec wish "$basedir/.tools/tcl_tools/menubar/uninstall.tcl"} result]} {
        tk_messageBox -type ok -icon error -title "Uninstall error" \
            -message "The uninstall confirmation window could not be opened."
        return
    }

    set result [string trim $result]
    if {$result == "1" || $result == "2"} {
        set clean_docker [expr {$result == "2" ? 1 : 0}]

        # Use a marker that cannot be confused with the normal 8/9-line GUI
        # protocol. Linux_launch.sh performs the destructive work only after
        # this GUI process has closed.
        puts "__DL4ME_UNINSTALL__"
        puts "$clean_docker"
        flush stdout
        exit 0
    }
}
proc cmddoc {}   {
    global basedir
    exec /bin/bash "$basedir/.tools/bash_tools/open_browser.sh" 1 "https://github.com/HenriquesLab/DL4MicEverywhere?tab=readme-ov-file#dl4miceverywhere" &
}

##### Create a window #####

# Create the window, give it a name, make it resizable and center its initial size.
wm title . "$window_title"
wm resizable . 1 1

set screen_width [winfo vrootwidth .]
set screen_height [winfo vrootheight .]

# Keep the initial window inside the available display. The minimum is also
# capped for unusually small virtual displays (for example some WSL setups).
set initial_width [expr {min($preferred_width, max(480, $screen_width - 80))}]
set initial_height [expr {min($preferred_height, max(500, $screen_height - 100))}]
set min_width [expr {min($minimum_width, $initial_width)}]
set min_height [expr {min($minimum_height, $initial_height)}]
wm minsize . $min_width $min_height

set width_offset [expr {max(0, ($screen_width - $initial_width) / 2)}]
set height_offset [expr {max(0, ($screen_height - $initial_height) / 2)}]
wm geometry . ${initial_width}x${initial_height}+${width_offset}+${height_offset}
