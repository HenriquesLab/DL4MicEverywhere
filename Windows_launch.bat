@echo off
setlocal EnableExtensions

rem =============================================================================
rem DL4MicEverywhere - Windows launcher
rem
rem Simple design:
rem   - Detect Docker Desktop.
rem   - Detect Windows Subsystem for Linux.
rem   - Detect an installed distribution whose registered name contains Ubuntu.
rem   - Use the exact detected Ubuntu name.
rem   - Never change the user's default WSL distribution.
rem   - Ask before every installation or file modification.
rem
rem IMPORTANT:
rem On the tested WSL version, passing the distribution as:
rem     -d "Ubuntu-26.04"
rem returns WSL_E_DISTRO_NOT_FOUND, while:
rem     -d Ubuntu-26.04
rem works correctly. Therefore the detected standard Ubuntu name is deliberately
rem passed to wsl.exe without quotes.
rem =============================================================================

set "SCRIPT_PATH=%~dp0"
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
set "BASEDIR=%SCRIPT_PATH%"
set "WSL_UTF8=1"

echo.
echo ============================================================
echo DL4MicEverywhere
echo ============================================================
echo This launcher checks the software needed by DL4MicEverywhere.
echo It will explain what it wants to do and ask permission before
echo installing software or modifying DL4MicEverywhere files.
echo.

rem =============================================================================
rem 1. Docker Desktop
rem =============================================================================

if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" goto :docker_ready

echo Docker Desktop was not found.
echo.
echo DL4MicEverywhere needs Docker Desktop to run its microscopy notebooks.
echo If you agree, the launcher will download the Docker Desktop installer
echo and start the normal Windows installation process.
echo.

call :ask_yes_no "Install Docker Desktop now?"
if errorlevel 1 goto :cancelled_docker

echo.
echo Downloading Docker Desktop...
bitsadmin.exe /transfer "DownloadDocker" "https://desktop.docker.com/win/main/amd64/136059/Docker Desktop Installer.exe" "%temp%\DockerDesktopInstaller.exe"
if not "%ERRORLEVEL%"=="0" goto :docker_install_failed

echo.
echo Starting the Docker Desktop installer...
powershell -NoProfile -Command "Start-Process '%temp%\DockerDesktopInstaller.exe' -Wait -ArgumentList 'install'"
if not "%ERRORLEVEL%"=="0" goto :docker_install_failed

echo.
echo ------------------------------------------------------------
echo Docker Desktop installation completed.
echo Please restart Windows before continuing with DL4MicEverywhere.
echo After restarting, double-click Windows_launch.bat again.
echo ------------------------------------------------------------
pause
exit /b 0

:docker_ready
echo Docker Desktop: found.

rem =============================================================================
rem 2. Windows Subsystem for Linux
rem =============================================================================

echo.
echo Checking Windows Subsystem for Linux...

where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :offer_wsl_install

wsl.exe --status >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :offer_wsl_install

echo Windows Subsystem for Linux: found.
goto :find_ubuntu

:offer_wsl_install
echo.
echo Windows Subsystem for Linux is not installed or is not ready.
echo.
echo DL4MicEverywhere needs Windows Subsystem for Linux and Ubuntu.
echo If you agree, Windows will install both components.
echo Windows may ask for administrator permission and may require a restart.
echo.

call :ask_yes_no "Install Windows Subsystem for Linux and Ubuntu now?"
if errorlevel 1 goto :cancelled_wsl

echo.
echo Asking Windows to install Windows Subsystem for Linux and Ubuntu...
powershell -NoProfile -Command "$p=Start-Process -FilePath 'wsl.exe' -ArgumentList '--install','-d','Ubuntu' -Verb RunAs -Wait -PassThru; exit $p.ExitCode"
if not "%ERRORLEVEL%"=="0" goto :wsl_install_failed

echo.
echo ------------------------------------------------------------
echo Installation completed.
echo Please restart Windows before continuing with DL4MicEverywhere.
echo After restarting, double-click Windows_launch.bat again.
echo ------------------------------------------------------------
pause
exit /b 0

rem =============================================================================
rem 3. Find an installed Ubuntu distribution
rem =============================================================================

:find_ubuntu
echo.
echo Looking for an installed Ubuntu distribution...

set "UBUNTU_DISTRO="

for /f "delims=" %%D in ('wsl.exe --list --quiet 2^>nul ^| findstr /i /c:"Ubuntu"') do if not defined UBUNTU_DISTRO set "UBUNTU_DISTRO=%%D"

if defined UBUNTU_DISTRO goto :ubuntu_found

echo.
echo No Ubuntu distribution was found inside Windows Subsystem for Linux.
echo.
echo If you agree, the launcher will ask Windows to install Ubuntu.
echo This adds Ubuntu to WSL but does NOT change your current default
echo WSL distribution.
echo.

call :ask_yes_no "Install Ubuntu now?"
if errorlevel 1 goto :cancelled_ubuntu

echo.
echo Asking Windows to install Ubuntu...
powershell -NoProfile -Command "$p=Start-Process -FilePath 'wsl.exe' -ArgumentList '--install','-d','Ubuntu' -Verb RunAs -Wait -PassThru; exit $p.ExitCode"
if not "%ERRORLEVEL%"=="0" goto :ubuntu_install_failed

echo.
echo ------------------------------------------------------------
echo Ubuntu installation completed.
echo.
echo The first time Ubuntu starts, Windows may ask you to choose a Linux
echo username and password. This is normal Ubuntu setup.
echo You do not need to type any DL4MicEverywhere commands.
echo.
echo Finish the Ubuntu setup if Windows opens it, then close Ubuntu and
echo double-click Windows_launch.bat again.
echo ------------------------------------------------------------
pause
exit /b 0

:ubuntu_found
echo Ubuntu distribution found: %UBUNTU_DISTRO%
echo DL4MicEverywhere will use this exact distribution name.
echo Your default WSL distribution will not be changed.

rem =============================================================================
rem 4. Verify Ubuntu
rem =============================================================================

echo.
echo Checking that %UBUNTU_DISTRO% can start...

rem Keep stderr visible so Windows can show the real WSL error.
wsl.exe -d %UBUNTU_DISTRO% --exec /bin/echo DL4ME_WSL_OK >nul
set "WSL_RESULT=%ERRORLEVEL%"

if "%WSL_RESULT%"=="0" goto :ubuntu_ready
goto :offer_wsl_restart

:offer_wsl_restart
echo.
echo %UBUNTU_DISTRO% is installed, but Windows Subsystem for Linux
echo did not respond correctly to a simple command.
echo.
echo This can happen when the WSL virtual machine gets stuck temporarily.
echo DL4MicEverywhere can restart Windows Subsystem for Linux and try again.
echo.
echo Restarting WSL will temporarily stop all WSL distributions.
echo This can also temporarily stop Docker Desktop because Docker uses WSL.
echo No Ubuntu files or DL4MicEverywhere files will be deleted.
echo.

call :ask_yes_no "Restart Windows Subsystem for Linux and try again now?"
if errorlevel 1 goto :cancelled_wsl_restart

echo.
echo Restarting Windows Subsystem for Linux...
wsl.exe --shutdown
set "WSL_SHUTDOWN_RESULT=%ERRORLEVEL%"

if "%WSL_SHUTDOWN_RESULT%"=="0" goto :wait_after_wsl_shutdown
goto :wsl_restart_failed

:wait_after_wsl_shutdown
echo Waiting 10 seconds for WSL to stop completely...
timeout /t 10 /nobreak >nul

echo.
echo Trying %UBUNTU_DISTRO% again...
wsl.exe -d %UBUNTU_DISTRO% --exec /bin/echo DL4ME_WSL_OK >nul
set "WSL_RETRY_RESULT=%ERRORLEVEL%"

if "%WSL_RETRY_RESULT%"=="0" goto :ubuntu_recovered
goto :ubuntu_still_unavailable

:ubuntu_recovered
echo Ubuntu: ready.
echo Windows Subsystem for Linux recovered successfully.
goto :after_ubuntu_health_check

:ubuntu_ready
echo Ubuntu: ready.

:after_ubuntu_health_check

rem =============================================================================
rem 5. Check dos2unix
rem =============================================================================

cd /d "%BASEDIR%"

wsl.exe -d %UBUNTU_DISTRO% --exec /bin/bash -c "command -v dos2unix >/dev/null 2>&1"
set "DOS2UNIX_CHECK=%ERRORLEVEL%"

if "%DOS2UNIX_CHECK%"=="0" goto :dos2unix_ready
if "%DOS2UNIX_CHECK%"=="1" goto :offer_dos2unix
goto :wsl_command_failed

:offer_dos2unix
echo.
echo DL4MicEverywhere needs a small Ubuntu utility called dos2unix.
echo It is used to make Windows text files compatible with Linux.
echo.
echo If you agree, the launcher will update Ubuntu's package list and
echo install dos2unix inside %UBUNTU_DISTRO%.
echo.

call :ask_yes_no "Install dos2unix now?"
if errorlevel 1 goto :cancelled_dos2unix

echo.
echo Installing dos2unix...
wsl.exe -d %UBUNTU_DISTRO% --user root --exec /bin/bash -c "apt-get -y update && apt-get -y install dos2unix"
set "DOS2UNIX_INSTALL=%ERRORLEVEL%"

if "%DOS2UNIX_INSTALL%"=="0" goto :dos2unix_ready
goto :dos2unix_install_failed

:dos2unix_ready
echo dos2unix: ready.

rem =============================================================================
rem 6. Prepare Linux shell scripts
rem =============================================================================

echo.
echo DL4MicEverywhere contains shell scripts that will run inside Ubuntu.
echo Windows and Linux use different text line endings, and Windows line
echo endings can prevent these scripts from running correctly.
echo.
echo If you agree, DL4MicEverywhere will run dos2unix on its .sh files.
echo This only normalizes text line endings; it does not change what the
echo scripts do.
echo.
echo It is safe to run this even when the files already use Linux line endings.
echo.

call :ask_yes_no "Prepare the DL4MicEverywhere shell scripts for Linux now?"
if errorlevel 1 goto :cancelled_conversion

echo.
echo Preparing DL4MicEverywhere shell scripts for Linux...

rem Convert only shell scripts. Avoid touching notebooks, images, YAML files,
rem Docker files, or other repository content unnecessarily.
wsl.exe -d %UBUNTU_DISTRO% --exec /bin/bash -c "find . -type f -name '*.sh' -print0 | xargs -0 -r dos2unix -q"
set "CONVERSION_RESULT=%ERRORLEVEL%"

if "%CONVERSION_RESULT%"=="0" goto :files_ready
goto :file_conversion_failed

:files_ready
echo Shell scripts: ready.

rem =============================================================================
rem 7. Start DL4MicEverywhere
rem =============================================================================

echo.
echo ============================================================
echo Starting DL4MicEverywhere using %UBUNTU_DISTRO%...
echo ============================================================
echo.

wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1 /bin/bash -E Linux_launch.sh
set "LAUNCH_RESULT=%ERRORLEVEL%"

if "%LAUNCH_RESULT%"=="0" exit /b 0
if "%LAUNCH_RESULT%"=="42" goto :complete_uninstall
goto :launch_failed

:complete_uninstall
echo.
echo DL4MicEverywhere is ready to be removed.
echo The DL4MicEverywhere application folder will now be deleted.

rem The running batch file lives inside the folder being deleted. Change to a
rem neutral directory and let a short-lived PowerShell child remove the folder
rem after this batch process exits.
set "DL4ME_UNINSTALL_DIR=%BASEDIR%"
cd /d "%TEMP%"
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 750; Remove-Item -LiteralPath $env:DL4ME_UNINSTALL_DIR -Recurse -Force" >nul 2>&1
exit /b 0


rem =============================================================================
rem Reusable yes/no question
rem Pressing Enter means No.
rem =============================================================================

:ask_yes_no
set "ANSWER="
set /p "ANSWER=%~1 (y/N): "
if /I "%ANSWER%"=="Y" exit /b 0
exit /b 1


rem =============================================================================
rem Friendly exits
rem =============================================================================

:cancelled_docker
echo.
echo Docker Desktop was not installed because you selected No.
echo Nothing else will be changed.
pause
exit /b 1

:cancelled_wsl
echo.
echo Windows Subsystem for Linux was not installed because you selected No.
echo Nothing else will be changed.
pause
exit /b 1

:cancelled_ubuntu
echo.
echo Ubuntu was not installed because you selected No.
echo Nothing else will be changed.
pause
exit /b 1

:cancelled_dos2unix
echo.
echo dos2unix was not installed because you selected No.
echo Nothing else will be changed.
pause
exit /b 1

:cancelled_conversion
echo.
echo The DL4MicEverywhere files were not modified because you selected No.
echo Nothing else will be changed.
pause
exit /b 1

:docker_install_failed
echo.
echo Docker Desktop could not be installed automatically.
echo No additional changes will be made.
pause
exit /b 1

:wsl_install_failed
echo.
echo Windows could not complete the Windows Subsystem for Linux installation.
echo No additional changes will be made.
pause
exit /b 1

:ubuntu_install_failed
echo.
echo Windows could not complete the Ubuntu installation.
echo No additional changes will be made.
pause
exit /b 1

:cancelled_wsl_restart
echo.
echo Windows Subsystem for Linux was not restarted because you selected No.
echo Nothing was changed by the recovery step.
echo.
echo DL4MicEverywhere cannot continue while Ubuntu is not responding.
echo You can close this window and try Windows_launch.bat again later.
pause
exit /b 1

:wsl_restart_failed
echo.
echo Windows could not restart Windows Subsystem for Linux automatically.
echo WSL returned exit code %WSL_SHUTDOWN_RESULT%.
echo No Ubuntu files or DL4MicEverywhere files were changed.
echo.
echo Please restart Windows and then run Windows_launch.bat again.
pause
exit /b 1

:ubuntu_still_unavailable
echo.
echo %UBUNTU_DISTRO% is still not responding after restarting WSL.
echo WSL returned exit code %WSL_RETRY_RESULT%.
echo.
echo DL4MicEverywhere will not reinstall Ubuntu because the distribution
echo is already present. No Ubuntu files or DL4MicEverywhere files were changed.
echo.
echo The safest next step is to restart Windows and then run
echo Windows_launch.bat again.
pause
exit /b 1

:dos2unix_install_failed
echo.
echo dos2unix could not be installed inside %UBUNTU_DISTRO%.
echo No additional changes will be made.
pause
exit /b 1

:file_conversion_failed
echo.
echo DL4MicEverywhere could not prepare the files for Linux.
echo No additional changes will be made.
pause
exit /b 1

:wsl_command_failed
echo.
echo A command inside %UBUNTU_DISTRO% returned an unexpected error.
echo No additional changes will be made.
echo Please review any error shown immediately above this message.
pause
exit /b 1

:launch_failed
echo.
echo DL4MicEverywhere did not start successfully inside %UBUNTU_DISTRO%.
echo The Linux launcher returned exit code %LAUNCH_RESULT%.
echo No additional changes will be made.
pause
exit /b 1