#! /usr/local/bin/wish

set width 400
set height 250
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

set yaml_types {
    {"All Source Files"     {.yaml } }
}

proc onSelectYaml { yaml_path } {
    global yaml_types
    set file [tk_getOpenFile -filetypes $yaml_types -parent .]
    $yaml_path configure -text $file
}

proc onSelectfolder { folder_path } {
    set file [tk_chooseDirectory -parent .]
    $folder_path configure -text $file
}


frame .fr
pack .fr -fill both -expand 1

frame .fr.pnl -relief raised -borderwidth 1
pack .fr.pnl -fill both -expand 1


ttk::button .fr.cb -text "Close" -command { exit 1 }
pack .fr.cb -padx 5 -pady 5 -side right 

ttk::button .fr.ok -text "OK" -command { exit 0 }
pack .fr.ok -side right



label .yp -text "....."
place .yp -x 240 -y 30

button .byp -text "Select configuration.yaml" \
        -command "onSelectYaml .yp"
place .byp -x 20 -y 30


label .ldp -text "......."
place .ldp -x 240 -y 60

button .bdp -text "Select data folder" \
        -command "onSelectfolder .ldp"
place .bdp -x 20 -y 60



wm title . "Center"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}

