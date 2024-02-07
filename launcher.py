import subprocess
import platform
import os
import sys

# Function to determine resource path
def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)

# Determine the OS
os_name = platform.system()

# Define the launch command based on the OS
if os_name == 'Windows':
    launch_command = resource_path('launch.bat')
elif os_name == 'Darwin':  # Darwin is the underlying OS for macOS
    launch_command = resource_path('launch.command')
elif os_name == 'Linux':
    launch_command = resource_path('launch.sh')
else:
    raise ValueError("Unsupported operating system")

# Append './' if necessary, depending on your specific launch commands
# For example, if your script needs to be executed from its directory
if os_name in ['Linux', 'Windows']:  # Adjust based on your requirement
    launch_command += " ./"

# Check if the launch file exists
if not os.path.exists(launch_command):
    raise FileNotFoundError(f"{launch_command} does not exist")

# Execute the launch command
try:
    print(f"Executing {launch_command} on {os_name}")
    result = subprocess.run(launch_command, check=True, shell=True)
    print("Execution successful.")
except subprocess.CalledProcessError as e:
    print(f"An error occurred while executing {launch_command}: {e}")
