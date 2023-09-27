#! /usr/local/bin/wish

set width 350
set height 250
set width_offset [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set height_offset [expr { ( [winfo vrootheight .] - $height ) / 2 }]

set types {
    {"All Source Files"     {.tcl .tk } }
    {"Image Files"          {.gif .png .jpg} }
    {"All files"            *}
}

proc onSelect { label } {
    global types
    set file [tk_getOpenFile -filetypes $types -parent .]
    $label configure -text $file
}

label .l -text "..."
place .l -x 20 -y 90

button .b -text "Select a file" \
        -command "onSelect .l"
place .b -x 20 -y 30


wm title . "Center"
wm geometry . ${width}x${height}+${width_offset}+${height_offset}
