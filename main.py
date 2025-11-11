import tkinter

import os
import platform
operating_system = platform.system()
print(operating_system)
# Initialize Tkinter root widget
root = tkinter.Tk()

# Define your Tcl script
# For demonstration, this is a simple script, but it could be the path to your existing Tcl script

# Path to your external Tcl script
tcl_script_path = '.tools/main_gui.tcl'

root.tk.setvar("basedir", "./")
root.tk.setvar("operative_system", operating_system.lower())

# Load and execute the Tcl script
with open(tcl_script_path, 'r') as file:
    tcl_script = file.read()
root.tk.call('eval', tcl_script)

# Start the Tkinter event loop (if necessary)
root.mainloop()


