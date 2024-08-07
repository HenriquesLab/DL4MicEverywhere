@echo off 
@setlocal

set WSL_UTF8=1
setlocal enabledelayedexpansion

set defaultdist=none
set /A isubuntu=0
set /A defaultubuntu=0

if not exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
  :: Download Docker Desktop
  bitsadmin.exe /transfer "DownloadDocker" "https://desktop.docker.com/win/main/amd64/136059/Docker Desktop Installer.exe" "%temp%\DockerDesktopInstaller.exe"
  :: Install it
  powershell -Command Start-Process "%temp%\DockerDesktopInstaller.exe" -Wait install

  :: Ask the user to restart its computer
  echo 
  echo ------------------------------------------------------------------------------------
  echo Docker Desktop installation completed!
  echo To ensure that all the changes are properly applied, please restart your computer.
  echo Then click the Windows_launcher.
  echo ------------------------------------------------------------------------------------
  pause
  exit
)

:: Check if WSL is installed
for /f "tokens=* USEBACKQ skip=1" %%g in (`wsl --status`) do (set wslworking=%%g)

:: In case is not installed, install it
if ["%wslworking%"]==[""] (
  wsl --install Ubuntu
  
  :: Ask the user to restart its computer
  echo 
  echo ------------------------------------------------------------------------------------
  echo Ubuntu in WSL installation completed!
  echo To ensure that all the changes are properly applied, please restart your computer. 
  echo Then click the Windows_launcher.
  echo ------------------------------------------------------------------------------------
  pause
  exit
)

:: Go trough all the WSL distributions in your computer
for /f "tokens=* USEBACKQ skip=1" %%F in (`wsl --list`) do (

  :: Get distribution name
  set "dist=%%F"

  :: Remove the word last parentheses in that name (that will be the default distribution)
  set "withoutparentheses=!dist:)=!"
  :: Check if the distrubution name contained paretheses (if so it is the default distribuition)
  if not !dist!==!withoutparentheses! set defaultdist=!dist!

  :: Remove the word Ubuntu in default distribution
  set "defaultubuntuless=!defaultdist:Ubuntu=!"
  :: Check if the default distrubution name contained Ubuntu
  if not !defaultdist!==!defaultubuntuless! set /A defaultubuntu=1
  
  :: Remove the word Ubuntu in the distribution name
  set "ubuntuless=!dist:Ubuntu=!"
  :: Check if the distrubution name contained Ubuntu
  if not !dist!==!ubuntuless! set /A isubuntu=1
)

:: First check if Ubuntu is installed
if %isubuntu%==0 (
  :: If it is not installed, install Ubuntu
  wsl --install Ubuntu
  wsl --set-default Ubuntu

  :: Ask the user to restart its computer
  echo 
  echo ------------------------------------------------------------------------------------
  echo Ubuntu in WSL installation completed!
  echo To ensure that all the changes are properly applied, please restart your computer. 
  echo Then click the Windows_launcher.
  echo ------------------------------------------------------------------------------------
  pause
  exit
) else (
  :: If it is intalled, check if it is the default distribution
  if %defaultubuntu%==0 (  
    :: If not, set as the default one
    wsl --set-default Ubuntu
  )
)

:: It might happen that by downloading it through 'git clone', the format of the files is on DOS/Windows.
:: We need it in a Unix/Linux format, that is why we need to install dos2unix if needed and use it.
wsl -d Ubuntu if command -v dos2unix -h 2>nul; then echo "dos2unix already installed."; else echo "Installing dos2unix..."; apt install dos2unix; fi

:: Check if for example Linux_launch.sh is on DOS format, and if so use dos2unix to convert it
wsl -d Ubuntu if [[ -n $(dos2unix --info=c "Linux_launch.sh") ]] ; then echo "Converting your files to Linux format..."; find . -type f -exec dos2unix -q '{}' '+'; fi

:: At this point Ubuntu is installed and as the default distribution, run the launch.sh inside the WSL
wsl -d Ubuntu bash -E Linux_launch.sh
