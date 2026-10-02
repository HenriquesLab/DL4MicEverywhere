# Cross-platform list helpers used by the DL4MicEverywhere Tcl GUI.
#
# Keep filesystem discovery in Tcl rather than parsing `find`, `xargs`, or
# other platform-specific command output.  Values are built with lappend so
# spaces and Tcl-special characters in directory names remain single elements.

proc dl4me_immediate_subdirectory_names {directory} {
    set names {}

    if {![file isdirectory $directory]} {
        return $names
    }

    # The bundled notebook categories are normal visible directories.  Using
    # Tcl's native glob keeps this portable across Linux, macOS, and Windows
    # Tcl runtimes and preserves paths containing spaces or special characters.
    foreach path [glob -nocomplain -types d -directory $directory *] {
        lappend names [file tail $path]
    }

    return [lsort -dictionary $names]
}

proc dl4me_nonempty_words {text} {
    set words {}
    foreach word [split $text] {
        if {$word ne ""} {
            lappend words $word
        }
    }
    return $words
}
