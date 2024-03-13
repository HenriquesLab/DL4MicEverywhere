import os
import subprocess
import webbrowser

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return result.stdout.strip()

def download_and_install_docker():
    docker_url = "https://desktop.docker.com/win/main/amd64/136059/Docker Desktop Installer.exe"
    docker_installer_path = os.path.join(os.environ["TEMP"], "DockerDesktopInstaller.exe")
    webbrowser.open(docker_url)
    print("------------------------------------------------------------------------------------")
    print("Docker Desktop installation started!")
    print("Please complete the installation process. Then, restart your computer.")
    print("Afterwards, run this script again.")
    print("------------------------------------------------------------------------------------")
    input("Press Enter to exit...")
    exit()

def install_wsl():
    run_command("wsl --install Ubuntu")
    print("------------------------------------------------------------------------------------")
    print("Ubuntu in WSL installation completed!")
    print("To ensure that all the changes are properly applied, please restart your computer.")
    print("Then run this script again.")
    print("------------------------------------------------------------------------------------")
    input("Press Enter to exit...")
    exit()

def set_default_ubuntu():
    run_command("wsl --set-default Ubuntu")

def check_docker_desktop():
    if not os.path.exists("C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe"):
        download_and_install_docker()

def check_wsl_and_ubuntu():
    wsl_status = run_command("wsl --status")
    if wsl_status == "":
        install_wsl()
    else:
        dist_list = run_command("wsl --list").splitlines()
        is_ubuntu_installed = any("Ubuntu" in dist for dist in dist_list)
        if not is_ubuntu_installed:
            install_wsl()
        else:
            default_dist = run_command("wsl -l -v | findstr '(Default)'")
            if "Ubuntu" not in default_dist:
                set_default_ubuntu()

def main():
    check_docker_desktop()
    check_wsl_and_ubuntu()
    # Execute the bash script within the default Ubuntu WSL instance
    run_command("wsl -d Ubuntu bash -E Linux_launch.sh")

if __name__ == "__main__":
    main()
