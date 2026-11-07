# Child-process helper used by the DL4MicEverywhere Tcl GUI.
#
# Tcl's plain `exec` raises an error whenever a child writes anything to
# stderr. On macOS every wish process logs harmless system messages there at
# startup (lines such as "2026-10-07 18:52:55.691 wish[76809:...] ..."), which
# made working dialogs (Preferences, About, Uninstall) look like failures.
#
# dl4me_exec passes the child's stderr through to the launcher terminal and
# returns its stdout. Only a non-zero exit status is an error; it is raised
# exactly like `exec` does (errorcode CHILDSTATUS pid status), so callers can
# still inspect it with `catch ... result options`.

proc dl4me_exec {args} {
    return [exec -ignorestderr -- {*}$args]
}
