@echo off
setlocal EnableExtensions

rem =============================================================================
rem DL4MicEverywhere - Windows launcher
rem
rem Fast-start design:
rem   - Docker Desktop is checked quickly on every launch.
rem   - WSL/Ubuntu discovery and shell-script preparation are first-run setup.
rem   - Successful setup is cached inside .tools\.cache\.windows_setup.
rem   - Normal launches reuse the cached Ubuntu distribution.
rem   - A short WSL readiness probe prevents multi-minute hangs.
rem   - Detailed WSL restart/recovery is only offered when the quick probe fails.
rem   - Linux shell scripts are normalized only when CRLF is actually detected.
rem   - Never change the user's default WSL distribution.
rem
rem Bump WINDOWS_SETUP_VERSION whenever a future release needs to repeat Windows
rem setup. Existing caches with an older version will then be ignored safely.
rem =============================================================================

set "WINDOWS_SETUP_VERSION=2"
set "SCRIPT_PATH=%~dp0"
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
set "BASEDIR=%SCRIPT_PATH%"
set "SETUP_CACHE=%BASEDIR%\.tools\.cache\.windows_setup"
set "WSL_UTF8=1"

rem =============================================================================
rem 1. Docker Desktop - this filesystem check is intentionally kept on every run.
rem =============================================================================

if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" goto :docker_ready

echo.
echo ============================================================
echo DL4MicEverywhere - Windows setup
echo ============================================================
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

rem =============================================================================
rem 2. Fast path - reuse a successful setup from this Windows computer.
rem =============================================================================

call :load_setup_cache
if errorlevel 1 goto :first_run_setup

set "UBUNTU_DISTRO=%CACHED_UBUNTU_DISTRO%"

echo.
echo ============================================================
echo DL4MicEverywhere
echo ============================================================
echo Windows setup: ready.
echo Ubuntu: %UBUNTU_DISTRO%

goto :fast_wsl_start

rem =============================================================================
rem 3. First-run / invalidated-cache setup
rem =============================================================================

:first_run_setup
echo.
echo ============================================================
echo DL4MicEverywhere - Windows setup
echo ============================================================
echo This setup is normally needed only once on this computer.
echo Future launches will reuse the successful setup automatically.
echo.
echo Docker Desktop: found.
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
rem 4. Find an installed Ubuntu distribution once and remember its exact name.
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

echo.
echo Checking that %UBUNTU_DISTRO% can start...
call :probe_wsl_with_retry
set "WSL_RESULT=%ERRORLEVEL%"
if "%WSL_RESULT%"=="0" goto :ubuntu_ready

set "AFTER_WSL_RECOVERY=ubuntu_ready"
goto :offer_wsl_restart

:ubuntu_ready
echo Ubuntu: ready.

rem =============================================================================
rem 5. Prepare Linux shell scripts only if Windows line endings are detected.
rem
rem This replaces the old unconditional dos2unix prompt. The repository also
rem includes .gitattributes so Git checkouts keep *.sh files as LF in the first
rem place. GNU sed is part of Ubuntu, so no extra dos2unix package is required.
rem =============================================================================

cd /d "%BASEDIR%"
echo.
echo Checking DL4MicEverywhere shell-script line endings...

wsl.exe -d %UBUNTU_DISTRO% --exec /bin/bash -c "if find . -type f -name '*.sh' -print0 | xargs -0 -r grep -Il $'\r' | grep -q .; then exit 10; else exit 0; fi"
set "LINE_ENDING_CHECK=%ERRORLEVEL%"

if "%LINE_ENDING_CHECK%"=="0" goto :scripts_ready
if "%LINE_ENDING_CHECK%"=="10" goto :normalize_scripts
goto :wsl_command_failed

:normalize_scripts
echo Windows line endings were detected in one or more shell scripts.
echo Normalizing only *.sh files to Linux line endings...

wsl.exe -d %UBUNTU_DISTRO% --exec /bin/bash -c "find . -type f -name '*.sh' -print0 | xargs -0 -r sed -i 's/\r$//'"
set "CONVERSION_RESULT=%ERRORLEVEL%"
if not "%CONVERSION_RESULT%"=="0" goto :file_conversion_failed

:scripts_ready
echo Shell scripts: ready.

call :write_setup_cache

goto :launch_application

rem =============================================================================
rem 6. Cached startup - no setup/discovery/dos2unix work.
rem
rem A short readiness probe is retained to avoid the old multi-minute WSL hang.
rem It is normally nearly instantaneous. If a cold WSL start is a little slow,
rem it gets one quiet retry before asking the user about restarting WSL.
rem =============================================================================

:fast_wsl_start
where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :cached_wsl_missing

cd /d "%BASEDIR%"
call :probe_wsl_with_retry
set "WSL_RESULT=%ERRORLEVEL%"
if "%WSL_RESULT%"=="0" goto :launch_application

set "AFTER_WSL_RECOVERY=launch_application"
goto :offer_wsl_restart

:cached_wsl_missing
echo The cached Windows setup is no longer valid because wsl.exe was not found.
del /q "%SETUP_CACHE%" >nul 2>&1
goto :offer_wsl_install

rem =============================================================================
rem 7. Start DL4MicEverywhere
rem =============================================================================

:launch_application
echo.
echo Starting DL4MicEverywhere using %UBUNTU_DISTRO%...
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
rem Cache helpers
rem =============================================================================

:load_setup_cache
set "CACHED_SETUP_VERSION="
set "CACHED_COMPUTER_NAME="
set "CACHED_UBUNTU_DISTRO="
set "CACHED_SCRIPTS_PREPARED="

if not exist "%SETUP_CACHE%" exit /b 1

for /f "usebackq tokens=1,* delims==" %%A in ("%SETUP_CACHE%") do (
    if /I "%%A"=="setup_version" set "CACHED_SETUP_VERSION=%%B"
    if /I "%%A"=="computer_name" set "CACHED_COMPUTER_NAME=%%B"
    if /I "%%A"=="ubuntu_distro" set "CACHED_UBUNTU_DISTRO=%%B"
    if /I "%%A"=="scripts_prepared" set "CACHED_SCRIPTS_PREPARED=%%B"
)

if not "%CACHED_SETUP_VERSION%"=="%WINDOWS_SETUP_VERSION%" exit /b 1
if /I not "%CACHED_COMPUTER_NAME%"=="%COMPUTERNAME%" exit /b 1
if not defined CACHED_UBUNTU_DISTRO exit /b 1
if not "%CACHED_SCRIPTS_PREPARED%"=="1" exit /b 1
exit /b 0

:write_setup_cache
if not exist "%BASEDIR%\.tools\.cache" mkdir "%BASEDIR%\.tools\.cache" >nul 2>&1

(
    echo setup_version=%WINDOWS_SETUP_VERSION%
    echo computer_name=%COMPUTERNAME%
    echo ubuntu_distro=%UBUNTU_DISTRO%
    echo scripts_prepared=1
) > "%SETUP_CACHE%"

if errorlevel 1 (
    echo.
    echo Warning: Windows setup completed, but its cache could not be saved.
    echo DL4MicEverywhere can still run, but setup checks may repeat next time.
    exit /b 0
)

echo Windows setup cached. Future launches will use the fast startup path.
exit /b 0

rem =============================================================================
rem Timed WSL readiness probe
rem
rem The old launcher let wsl.exe wait for Windows' own long timeout. This helper
rem caps each probe at 7 seconds. A timed-out wsl.exe client is terminated; the
rem WSL virtual machine itself is not shut down unless the user explicitly
rem agrees to the recovery step below.
rem =============================================================================

:quick_wsl_probe
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $p=Start-Process -FilePath 'wsl.exe' -ArgumentList @('-d','%UBUNTU_DISTRO%','--exec','/bin/true') -NoNewWindow -PassThru; if ($p.WaitForExit(7000)) { exit $p.ExitCode } else { try { $p.Kill() } catch {}; exit 124 } } catch { exit 125 }" >nul 2>&1
exit /b %ERRORLEVEL%

:probe_wsl_with_retry
call :quick_wsl_probe
if not errorlevel 1 exit /b 0

rem A cold WSL VM can need a moment. Give it one quiet retry before presenting
rem any recovery UI to the user.
timeout /t 2 /nobreak >nul
call :quick_wsl_probe
exit /b %ERRORLEVEL%

rem =============================================================================
rem WSL recovery - reached only after the short readiness probes fail.
rem =============================================================================

:offer_wsl_restart
echo.
echo %UBUNTU_DISTRO% is installed, but Windows Subsystem for Linux
echo is not responding quickly enough to start DL4MicEverywhere.
echo.
echo DL4MicEverywhere can restart Windows Subsystem for Linux and try again.
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
if not "%WSL_SHUTDOWN_RESULT%"=="0" goto :wsl_restart_failed

rem Do not impose the old fixed 10-second wait. Start checking after two seconds
rem and continue as soon as Ubuntu is actually ready.
timeout /t 2 /nobreak >nul
set "WSL_RECOVERY_ATTEMPT=1"

:wsl_recovery_retry
call :quick_wsl_probe
set "WSL_RETRY_RESULT=%ERRORLEVEL%"
if "%WSL_RETRY_RESULT%"=="0" goto :ubuntu_recovered

if "%WSL_RECOVERY_ATTEMPT%"=="3" goto :ubuntu_still_unavailable
set /a WSL_RECOVERY_ATTEMPT+=1
timeout /t 2 /nobreak >nul
goto :wsl_recovery_retry

:ubuntu_recovered
echo Ubuntu: ready.
echo Windows Subsystem for Linux recovered successfully.
goto :%AFTER_WSL_RECOVERY%

rem =============================================================================
rem Reusable yes/no question. Pressing Enter means No.
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
echo Last readiness probe returned exit code %WSL_RETRY_RESULT%.
echo.
echo No Ubuntu files or DL4MicEverywhere files were changed.
echo The safest next step is to restart Windows and then run
echo Windows_launch.bat again.
pause
exit /b 1

:file_conversion_failed
echo.
echo DL4MicEverywhere detected Windows line endings but could not normalize
echo the shell scripts for Linux. No additional changes will be made.
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
