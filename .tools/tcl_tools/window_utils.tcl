# Each DL4MicEverywhere dialog runs in its own wish process started from the
# terminal. Since macOS 14 such a process can no longer make itself the active
# application, so its window opens behind the Terminal window and the launcher
# looks stuck. A "topmost" window is drawn above the windows of other
# applications without activating its own, so the dialog is visible. When the
# user clicks it, wish becomes the active application and the window goes back
# to normal stacking, so it does not cover other applications afterwards.
proc dl4me_bring_to_front {{w .}} {
    update idletasks
    wm deiconify $w
    raise $w
    catch {wm attributes $w -topmost 1}
    catch {focus -force $w}
    bind $w <ButtonPress> +[list catch [list wm attributes $w -topmost 0]]
}
