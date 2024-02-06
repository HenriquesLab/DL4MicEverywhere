@echo off 
@setlocal

set WSL_UTF8=1
setlocal enabledelayedexpansion

set defaultdist=none
set /A isubuntu=0

:: Go trough all the WSL distributions in your computer
for /f "tokens=* USEBACKQ skip=1" %%F in (`wsl --list`) do (

  :: Get distribution name
  set "dist=%%F"

  :: Remove the word Default in that name
  set "defaultless=!dist:Default=!"

  :: Check if the distrubution name contained Default
  if not !dist!==!defaultless! set defaultdist=!defaultless:~0,-3!

  :: Remove the word Ubuntu in that name
  set "ubuntuless=!dist:Ubuntu=!"

  :: Check if the distrubution name contained Default
  if not !dist!==!ubuntuless! set /A isubuntu=1

)

:: First check if Ubuntu is installed
if %defaultdist%==0 (
  :: If it is not installed, install Ubuntu
  wsl.exe --install Ubuntu
) else (
  :: If it is intalled, check if it is the default distribution
  if not %defaultdist%==Ubuntu (
    :: If not, set as the default one
    wsl --set-default Ubuntu
  )
)

:: At this point Ubuntu is installed and as the default distribution, run the launch.sh inside the WSL
wsl.exe -d Ubuntu bash -E launch.sh
