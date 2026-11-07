import subprocess
import platform
import os
import sys
# from dl4miceverywhere import windows_launch


# Function to determine resource path
def resource_path(relative_path):
    """Get absolute path to resource, works for dev and for PyInstaller"""
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)


# Determine the OS
os_name = platform.system()

# Define the launch command based on the OS
if os_name == "Windows":
    # windows_launch.main()
    launch_command = resource_path("Windows_launch.bat")
elif os_name == "Darwin":  # Darwin is the underlying OS for macOS
    launch_command = resource_path("MacOS_launch.command")
elif os_name == "Linux":
    launch_command = resource_path("Linux_launch.sh")
else:
    raise ValueError("Unsupported operating system")

# Append './' if necessary, depending on your specific launch commands
# For example, if your script needs to be executed from its directory
# if os_name in ['Linux', 'Windows']:  # Adjust based on your requirement


# Check if the launch file exists
if not os.path.exists(launch_command):
    raise FileNotFoundError(f"{launch_command} does not exist")

# launch_command += " ./"

# Execute the launch command and preserve its status. Unix launchers are passed
# as argv to Bash so repository/application paths containing spaces are safe.
print(f"Executing {launch_command} on {os_name}")
if os_name == "Windows":
    result = subprocess.run(f'"{launch_command}"', shell=True, check=False)
else:
    result = subprocess.run(["/bin/bash", launch_command], check=False)

if result.returncode == 0:
    print("Execution successful.")
else:
    print(f"Launcher exited with status {result.returncode}.")

sys.exit(result.returncode)
