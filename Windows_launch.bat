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
rem   - A bounded WSL readiness probe prevents multi-minute hangs while still
rem     allowing enough time for a cold WSL distro to initialize normally.
rem   - Detailed WSL restart/recovery is only offered when that bounded probe fails.
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
set "UBUNTU_SETUP_PENDING=%BASEDIR%\.tools\.cache\.ubuntu_setup_pending"
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

rem The cache records the distro that worked previously, but users can later
rem unregister, rename, or replace WSL distributions. Treat the cached value as
rem a hint and verify that the exact distro name is still registered.
where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :cached_wsl_missing

call :distro_is_registered
set "CACHED_DISTRO_RESULT=%ERRORLEVEL%"
if "%CACHED_DISTRO_RESULT%"=="1" goto :cached_distro_stale

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

rem If a previous Ubuntu first-run setup was interrupted, resume it before
rem normal distro discovery. This marker is removed only after setup succeeds.
if exist "%UBUNTU_SETUP_PENDING%" goto :resume_ubuntu_first_setup
goto :find_ubuntu

:resume_ubuntu_first_setup
set "UBUNTU_DISTRO="
set /p UBUNTU_DISTRO=<"%UBUNTU_SETUP_PENDING%"
if not defined UBUNTU_DISTRO goto :clear_stale_ubuntu_setup_pending

call :distro_is_registered
set "PENDING_DISTRO_RESULT=%ERRORLEVEL%"
if "%PENDING_DISTRO_RESULT%"=="0" (
    echo.
    echo Resuming the one-time Ubuntu user setup for %UBUNTU_DISTRO%...
    set "UBUNTU_NEEDS_FIRST_SETUP=1"
    goto :ubuntu_first_setup
)

:clear_stale_ubuntu_setup_pending
del /q "%UBUNTU_SETUP_PENDING%" >nul 2>&1
set "UBUNTU_DISTRO="
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
powershell -NoProfile -Command "$p=Start-Process -FilePath 'wsl.exe' -ArgumentList '--install -d Ubuntu' -Verb RunAs -Wait -PassThru; exit $p.ExitCode"
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

if defined UBUNTU_DISTRO (
    if "%UBUNTU_NEEDS_FIRST_SETUP%"=="1" goto :ubuntu_first_setup
    goto :ubuntu_found
)

rem wsl --install --no-launch normally registers the distro before returning.
rem If it did not, do not offer a second installation immediately; report the
rem incomplete registration so the user gets a clear recovery message.
if "%UBUNTU_INSTALL_PENDING%"=="1" goto :ubuntu_registration_failed

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
echo The installation will not open a separate Ubuntu terminal.
powershell -NoProfile -Command "$p=Start-Process -FilePath 'wsl.exe' -ArgumentList '--install -d Ubuntu --no-launch' -Verb RunAs -Wait -PassThru; exit $p.ExitCode"
if not "%ERRORLEVEL%"=="0" goto :ubuntu_install_failed

echo.
echo Ubuntu installation completed.
echo Waiting for Windows to register the new Ubuntu distribution...
timeout /t 2 /nobreak >nul

set "UBUNTU_NEEDS_FIRST_SETUP=1"
set "UBUNTU_INSTALL_PENDING=1"
goto :find_ubuntu

:ubuntu_first_setup
rem Persist the pending first-run state so an interrupted setup is resumed on
rem the next launch instead of treating the distro as fully configured.
if not exist "%BASEDIR%\.tools\.cache" mkdir "%BASEDIR%\.tools\.cache" >nul 2>&1
>"%UBUNTU_SETUP_PENDING%" echo %UBUNTU_DISTRO%

echo.
echo ------------------------------------------------------------
echo Ubuntu needs a one-time user setup before DL4MicEverywhere can run.
echo.
echo Please choose your Linux username and password when Ubuntu asks for
echo them below. The password will not be shown while you type it.
echo.
echo When the Ubuntu setup is complete, this launcher will continue
echo automatically. You do not need to close or restart anything.
echo ------------------------------------------------------------
echo.

rem The first launch performs Ubuntu's normal user-account setup. Running a
rem short interactive login shell with an explicit exit keeps that first run in
rem this console and returns control to Windows_launch.bat when setup finishes.
wsl.exe -d %UBUNTU_DISTRO% --exec /bin/bash -lic "exit"
set "UBUNTU_SETUP_RESULT=%ERRORLEVEL%"
if not "%UBUNTU_SETUP_RESULT%"=="0" goto :ubuntu_first_setup_failed

set "UBUNTU_NEEDS_FIRST_SETUP="
del /q "%UBUNTU_SETUP_PENDING%" >nul 2>&1
echo.
echo Ubuntu user setup completed.
goto :ubuntu_found

:ubuntu_found
set "UBUNTU_INSTALL_PENDING="
echo Ubuntu distribution found: %UBUNTU_DISTRO%
echo DL4MicEverywhere will use this exact distribution name.
echo Your default WSL distribution will not be changed.

echo.
echo Checking that %UBUNTU_DISTRO% can start...
set "AFTER_WSL_RECOVERY=ubuntu_ready"
call :probe_wsl_with_retry
set "WSL_RESULT=%ERRORLEVEL%"
if "%WSL_RESULT%"=="0" goto :ubuntu_ready
if "%WSL_RESULT%"=="2" goto :offer_wsl_restart
set "WSL_COMMAND_RESULT=%WSL_RESULT%"
goto :wsl_readiness_command_failed

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

goto :ensure_docker_wsl_integration

rem =============================================================================
rem 6. Cached startup - no setup/discovery/dos2unix work.
rem
rem A bounded readiness probe is retained to avoid the old multi-minute WSL hang.
rem It normally returns almost immediately, but allows up to 30 seconds for a
rem genuinely cold distro start before offering WSL recovery.
rem =============================================================================

:fast_wsl_start
where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :cached_wsl_missing

cd /d "%BASEDIR%"
set "AFTER_WSL_RECOVERY=ensure_docker_wsl_integration"
call :probe_wsl_with_retry
set "WSL_RESULT=%ERRORLEVEL%"
if "%WSL_RESULT%"=="0" goto :ensure_docker_wsl_integration

rem A failed probe may mean WSL is stuck, but it may also mean the cached distro
rem disappeared between validation and startup. Re-check registration before
rem deciding how to recover.
call :distro_is_registered
set "DISTRO_RECHECK_RESULT=%ERRORLEVEL%"
if "%DISTRO_RECHECK_RESULT%"=="1" goto :cached_distro_stale

rem Only a timeout is classified as an unresponsive WSL service. If WSL returned
rem promptly with a non-zero command result, restarting the VM repeatedly is not
rem a useful first response; show the captured diagnostic instead.
if "%WSL_RESULT%"=="2" goto :offer_wsl_restart
set "WSL_COMMAND_RESULT=%WSL_RESULT%"
goto :wsl_readiness_command_failed

:cached_distro_stale
echo.
echo The cached Ubuntu distribution "%UBUNTU_DISTRO%" is no longer installed.
echo DL4MicEverywhere will search for another installed Ubuntu distribution.
del /q "%SETUP_CACHE%" >nul 2>&1
set "CACHED_UBUNTU_DISTRO="
set "UBUNTU_DISTRO="
goto :find_ubuntu

:cached_wsl_missing
echo The cached Windows setup is no longer valid because wsl.exe was not found.
del /q "%SETUP_CACHE%" >nul 2>&1
goto :offer_wsl_install

rem =============================================================================
rem 7. Verify Docker Desktop WSL integration for the selected Ubuntu distro.
rem
rem The most reliable test is the capability DL4MicEverywhere actually needs:
rem can Docker be reached from this exact WSL distribution? If it already works,
rem no settings are read or changed. Automatic repair is attempted only after
rem explicit user consent and only when Docker Desktop itself is healthy on
rem Windows, so a stopped Docker daemon is not mistaken for missing integration.
rem =============================================================================

:ensure_docker_wsl_integration
rem Revalidate the selected distro at the boundary where Docker integration is
rem tested. A distro can be unregistered while WSL/Docker Desktop is restarting.
call :distro_is_registered
set "DOCKER_DISTRO_CHECK_RESULT=%ERRORLEVEL%"
if "%DOCKER_DISTRO_CHECK_RESULT%"=="1" goto :cached_distro_stale
if not "%DOCKER_DISTRO_CHECK_RESULT%"=="0" (
    set "AFTER_WSL_RECOVERY=ensure_docker_wsl_integration"
    goto :offer_wsl_restart
)

echo.
echo Checking Docker Desktop integration with %UBUNTU_DISTRO%...
call :docker_works_in_wsl
set "WSL_DOCKER_RESULT=%ERRORLEVEL%"
if "%WSL_DOCKER_RESULT%"=="0" (
    echo Docker integration: ready.
    goto :launch_application
)

rem If this WSL command failed because the distro disappeared during the tiny
rem interval after the registration check, rediscover Ubuntu instead of
rem misreporting the problem as missing Docker Desktop integration.
call :distro_is_registered
set "DOCKER_DISTRO_RECHECK_RESULT=%ERRORLEVEL%"
if "%DOCKER_DISTRO_RECHECK_RESULT%"=="1" goto :cached_distro_stale
if not "%DOCKER_DISTRO_RECHECK_RESULT%"=="0" (
    set "AFTER_WSL_RECOVERY=ensure_docker_wsl_integration"
    goto :offer_wsl_restart
)

rem If Docker is unavailable from WSL, first confirm that the Windows-side
rem Docker daemon is healthy. Otherwise the problem is Docker Desktop itself,
rem not necessarily WSL integration.
call :windows_docker_works
set "WINDOWS_DOCKER_RESULT=%ERRORLEVEL%"
if not "%WINDOWS_DOCKER_RESULT%"=="0" goto :offer_docker_start_for_integration

:docker_windows_ready_for_integration
echo.
echo Docker Desktop is running on Windows, but Docker is not available inside:
echo.
echo     %UBUNTU_DISTRO%
echo.
echo DL4MicEverywhere needs Docker Desktop WSL integration for this Ubuntu
echo distribution in order to build and run notebook images.
echo.
echo If you agree, DL4MicEverywhere will:
echo   - stop Docker Desktop using the supported Desktop CLI when available,
echo     or request a normal Windows shutdown on older Docker Desktop versions,
echo   - back up your Docker Desktop settings,
echo   - add %UBUNTU_DISTRO% to the WSL integration list,
echo   - start Docker Desktop again, and
echo   - verify Docker access from %UBUNTU_DISTRO%.
echo.
echo Existing WSL integrations will be preserved.
echo.

call :ask_yes_no "Enable Docker integration for %UBUNTU_DISTRO% now?"
if errorlevel 1 goto :cancelled_docker_wsl_integration

call :enable_docker_wsl_integration
set "DOCKER_WSL_ENABLE_RESULT=%ERRORLEVEL%"
if not "%DOCKER_WSL_ENABLE_RESULT%"=="0" goto :docker_wsl_integration_enable_failed

call :wait_for_docker_wsl_integration
set "DOCKER_WSL_VERIFY_RESULT=%ERRORLEVEL%"
if not "%DOCKER_WSL_VERIFY_RESULT%"=="0" goto :docker_wsl_integration_verify_failed

echo Docker integration: ready.
goto :launch_application

rem =============================================================================
rem Docker Desktop / WSL integration helpers
rem =============================================================================

:docker_works_in_wsl
rem Keep the check quiet: a missing docker command, missing integration socket,
rem or unreachable daemon all mean this distro is not currently usable by
rem DL4MicEverywhere. Windows Docker is checked separately to classify the cause.
wsl.exe -d %UBUNTU_DISTRO% --exec /bin/sh -lc "command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1" >nul 2>&1
set "WSL_DOCKER_PROBE_RESULT=%ERRORLEVEL%"
if "%WSL_DOCKER_PROBE_RESULT%"=="0" exit /b 0
exit /b 1

:windows_docker_works
set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if not exist "%DOCKER_EXE%" exit /b 2
"%DOCKER_EXE%" info >nul 2>&1
exit /b %ERRORLEVEL%

:desktop_cli_available
set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if not exist "%DOCKER_EXE%" exit /b 1
"%DOCKER_EXE%" desktop version >nul 2>&1
exit /b %ERRORLEVEL%

:start_docker_desktop
set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
set "DOCKER_DESKTOP_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"

call :desktop_cli_available
if "%ERRORLEVEL%"=="0" (
    "%DOCKER_EXE%" desktop start --timeout 120 >nul 2>&1
    exit /b 0
)

rem Older Docker Desktop versions may not provide the Desktop CLI plugin. The
rem normal application executable is a safe fallback for starting Docker.
if not exist "%DOCKER_DESKTOP_EXE%" exit /b 1
start "" "%DOCKER_DESKTOP_EXE%"
exit /b 0

:stop_docker_desktop
set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"

call :desktop_cli_available
if "%ERRORLEVEL%"=="0" (
    "%DOCKER_EXE%" desktop stop --timeout 60 >nul 2>&1
    if "%ERRORLEVEL%"=="0" exit /b 0
    rem A supported Desktop CLI that cannot stop Docker is treated as a real
    rem shutdown failure; do not fall through to forceful process termination.
    exit /b 1
)

rem Compatibility path for Docker Desktop releases that predate the Desktop CLI.
rem taskkill without /F requests normal termination rather than force-killing the
rem processes. If Docker does not close promptly, abort the automatic settings
rem edit and let the user use Docker Desktop's GUI instead.
taskkill /IM "Docker Desktop.exe" /T >nul 2>&1
set "DOCKER_CLOSE_REQUEST=%ERRORLEVEL%"
if not "%DOCKER_CLOSE_REQUEST%"=="0" exit /b 2

set "DOCKER_STOP_ATTEMPT=1"
:docker_stop_retry
call :docker_desktop_processes_stopped
if "%ERRORLEVEL%"=="0" exit /b 0
if "%DOCKER_STOP_ATTEMPT%"=="30" exit /b 3
set /a DOCKER_STOP_ATTEMPT+=1
timeout /t 1 /nobreak >nul
goto :docker_stop_retry

:docker_desktop_processes_stopped
tasklist /FI "IMAGENAME eq Docker Desktop.exe" 2>nul | findstr /I /C:"Docker Desktop.exe" >nul
if "%ERRORLEVEL%"=="0" exit /b 1
tasklist /FI "IMAGENAME eq com.docker.backend.exe" 2>nul | findstr /I /C:"com.docker.backend.exe" >nul
if "%ERRORLEVEL%"=="0" exit /b 1
exit /b 0

:wait_for_windows_docker
set "WINDOWS_DOCKER_ATTEMPT=1"

:windows_docker_retry
call :windows_docker_works
if "%ERRORLEVEL%"=="0" exit /b 0
if "%WINDOWS_DOCKER_ATTEMPT%"=="24" exit /b 1
set /a WINDOWS_DOCKER_ATTEMPT+=1
timeout /t 5 /nobreak >nul
goto :windows_docker_retry

:enable_docker_wsl_integration
set "DOCKER_WSL_HELPER=%BASEDIR%\.tools\windows_tools\docker_wsl_integration.ps1"
if not exist "%DOCKER_WSL_HELPER%" exit /b 21

echo.
echo Stopping Docker Desktop...
call :stop_docker_desktop
set "DOCKER_STOP_RESULT=%ERRORLEVEL%"
if not "%DOCKER_STOP_RESULT%"=="0" exit /b 22

echo Updating Docker Desktop WSL integration settings...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DOCKER_WSL_HELPER%" -Action enable -Distro "%UBUNTU_DISTRO%"
set "SETTINGS_UPDATE_RESULT=%ERRORLEVEL%"
if not "%SETTINGS_UPDATE_RESULT%"=="0" (
    echo Restarting Docker Desktop without applying changes...
    call :start_docker_desktop
    call :wait_for_windows_docker
    exit /b 23
)

echo Starting Docker Desktop...
call :start_docker_desktop
set "DOCKER_START_RESULT=%ERRORLEVEL%"
if not "%DOCKER_START_RESULT%"=="0" goto :docker_integration_start_failed

call :wait_for_windows_docker
set "DOCKER_START_READY_RESULT=%ERRORLEVEL%"
if "%DOCKER_START_READY_RESULT%"=="0" exit /b 0

:docker_integration_start_failed
rem If Docker Desktop cannot start after editing its settings, restore the
rem backup from this exact repair attempt before one final start attempt.
echo Docker Desktop did not start after the settings update.
echo Restoring the Docker Desktop settings backup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DOCKER_WSL_HELPER%" -Action restore >nul 2>&1
call :start_docker_desktop
call :wait_for_windows_docker
exit /b 24

:wait_for_docker_wsl_integration
rem Docker Desktop can be ready on Windows a few seconds before its per-distro
rem WSL integration agent is ready. Retry briefly, then fail with manual steps.
set "DOCKER_INTEGRATION_ATTEMPT=1"

:docker_integration_retry
call :docker_works_in_wsl
if "%ERRORLEVEL%"=="0" exit /b 0
if "%DOCKER_INTEGRATION_ATTEMPT%"=="12" exit /b 1
set /a DOCKER_INTEGRATION_ATTEMPT+=1
timeout /t 5 /nobreak >nul
goto :docker_integration_retry

rem =============================================================================
rem 8. Start DL4MicEverywhere
rem =============================================================================

:launch_application
echo.
echo Starting DL4MicEverywhere using %UBUNTU_DISTRO%...
echo.

wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1 /bin/bash -E Linux_launch.sh
set "LAUNCH_RESULT=%ERRORLEVEL%"

if "%LAUNCH_RESULT%"=="0" exit /b 0
if "%LAUNCH_RESULT%"=="42" goto :complete_uninstall

rem If the selected distro was unregistered after the preflight check but before
rem this command started, recover by rediscovering Ubuntu instead of reporting a
rem misleading Linux launcher failure. Other non-zero launcher results remain
rem genuine application errors and are reported below.
call :distro_is_registered
set "POST_LAUNCH_DISTRO_RESULT=%ERRORLEVEL%"
if "%POST_LAUNCH_DISTRO_RESULT%"=="1" goto :cached_distro_stale

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
rem uses a bounded probe: 30 seconds on normal startup and 45 seconds after an
rem explicit WSL shutdown. The command is executed as root so distro readiness
rem is not confused with a problem in the configured default Ubuntu user.
rem =============================================================================

:distro_is_registered
rem Check the exact cached/selected distro name without starting the distro.
rem PowerShell is used here because it handles WSL's Unicode list output cleanly.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$target=$env:UBUNTU_DISTRO; try { $distros=@(& wsl.exe --list --quiet 2>$null); if ($LASTEXITCODE -ne 0) { exit 2 }; if ($distros | Where-Object { (($_ -replace '\x00','').Trim()) -eq $target }) { exit 0 } else { exit 1 } } catch { exit 2 }" >nul 2>&1
exit /b %ERRORLEVEL%

:timed_wsl_probe
rem Run one minimal command as root inside the selected distro. The PowerShell
rem helper uses a single native ArgumentList string for Start-Process rather than
rem an argument array, avoiding command-line reconstruction differences.
setlocal
set "WSL_PROBE_TIMEOUT_MS=%~1"
if not defined WSL_PROBE_TIMEOUT_MS set "WSL_PROBE_TIMEOUT_MS=30000"
set "WSL_READINESS_HELPER=%BASEDIR%\.tools\windows_tools\wsl_readiness.ps1"
if not exist "%WSL_READINESS_HELPER%" endlocal & exit /b 3
powershell -NoProfile -ExecutionPolicy Bypass -File "%WSL_READINESS_HELPER%" -Action timed -Distro "%UBUNTU_DISTRO%" -TimeoutMilliseconds %WSL_PROBE_TIMEOUT_MS% >nul 2>&1
set "TIMED_WSL_RESULT=%ERRORLEVEL%"
endlocal & exit /b %TIMED_WSL_RESULT%

:direct_wsl_probe
rem If the bounded wrapper reports a quick command error, automatically confirm
rem readiness with PowerShell's direct native-command invocation. This performs
rem the equivalent of `wsl -d DISTRO -u root --exec /bin/true` without asking the
rem user to open another terminal or copy/paste any commands.
setlocal
set "WSL_READINESS_HELPER=%BASEDIR%\.tools\windows_tools\wsl_readiness.ps1"
if not exist "%WSL_READINESS_HELPER%" endlocal & exit /b 3
powershell -NoProfile -ExecutionPolicy Bypass -File "%WSL_READINESS_HELPER%" -Action direct -Distro "%UBUNTU_DISTRO%" >nul 2>&1
set "DIRECT_WSL_RESULT=%ERRORLEVEL%"
endlocal & exit /b %DIRECT_WSL_RESULT%

:probe_wsl_with_retry
rem Normal startup gets one bounded probe. If WSL answers promptly but the
rem wrapper reports a command error, DL4MicEverywhere automatically repeats the
rem same readiness test through a direct native WSL invocation. If that succeeds,
rem startup continues immediately with no user intervention.
call :timed_wsl_probe 30000
set "WSL_PROBE_RESULT=%ERRORLEVEL%"
if "%WSL_PROBE_RESULT%"=="0" exit /b 0
if "%WSL_PROBE_RESULT%"=="2" exit /b 2
call :direct_wsl_probe
set "DIRECT_WSL_RESULT=%ERRORLEVEL%"
if "%DIRECT_WSL_RESULT%"=="0" exit /b 0
if "%WSL_PROBE_RESULT%"=="3" exit /b 3
exit /b 1

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

rem After a full WSL shutdown, give Ubuntu one uninterrupted cold-start window.
rem Several short probes can repeatedly terminate the WSL client before the distro
rem finishes initializing, creating a false "still not responding" loop.
timeout /t 2 /nobreak >nul
call :timed_wsl_probe 45000
set "WSL_RETRY_RESULT=%ERRORLEVEL%"
if "%WSL_RETRY_RESULT%"=="0" goto :ubuntu_recovered
if "%WSL_RETRY_RESULT%"=="2" goto :ubuntu_still_unavailable
call :direct_wsl_probe
set "DIRECT_WSL_RESULT=%ERRORLEVEL%"
if "%DIRECT_WSL_RESULT%"=="0" goto :ubuntu_recovered
set "WSL_COMMAND_RESULT=%WSL_RETRY_RESULT%"
goto :wsl_readiness_command_failed

:ubuntu_recovered
rem A successful /bin/true probe is not enough on its own: re-check the current
rem registered distro list before declaring recovery complete. This also catches
rem a distro being removed/replaced while Docker Desktop or WSL was restarting.
call :distro_is_registered
set "RECOVERED_DISTRO_RESULT=%ERRORLEVEL%"
if "%RECOVERED_DISTRO_RESULT%"=="1" goto :cached_distro_stale
if not "%RECOVERED_DISTRO_RESULT%"=="0" (
    set "WSL_RETRY_RESULT=%RECOVERED_DISTRO_RESULT%"
    goto :ubuntu_still_unavailable
)

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

:ubuntu_registration_failed
set "UBUNTU_INSTALL_PENDING="
set "UBUNTU_NEEDS_FIRST_SETUP="
echo.
echo Windows reported that Ubuntu was installed, but the new distribution
echo has not appeared in the WSL distribution list yet.
echo.
echo Please restart Windows and then run Windows_launch.bat again.
echo DL4MicEverywhere will automatically detect the installed Ubuntu distro.
pause
exit /b 1

:ubuntu_first_setup_failed
echo.
echo Ubuntu was installed, but its one-time user setup did not complete
echo successfully. The Ubuntu setup returned exit code %UBUNTU_SETUP_RESULT%.
echo.
echo No Ubuntu distribution or DL4MicEverywhere files will be removed.
echo The pending setup has been remembered. Run Windows_launch.bat again
echo and DL4MicEverywhere will resume the Ubuntu user setup automatically.
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

:wsl_readiness_command_failed
echo.
echo %UBUNTU_DISTRO% is registered and WSL responded, but both automatic Ubuntu
echo readiness methods returned an error.
echo.
echo DL4MicEverywhere already tested the distro as root using both a bounded
echo process probe and a direct native WSL command. You do not need to run any
echo diagnostic commands yourself.
echo.
if exist "%TEMP%\dl4me_wsl_probe_stderr.txt" (
    for %%A in ("%TEMP%\dl4me_wsl_probe_stderr.txt") do if %%~zA GTR 0 (
        echo WSL diagnostic output:
        type "%TEMP%\dl4me_wsl_probe_stderr.txt"
        echo.
    )
)
echo DL4MicEverywhere can restart only %UBUNTU_DISTRO% and retry automatically.
echo This stops processes inside that Ubuntu distro but does not delete files or
echo affect other WSL distributions.
echo.
call :ask_yes_no "Restart %UBUNTU_DISTRO% and try again now?"
if errorlevel 1 goto :cancelled_ubuntu_restart

echo.
echo Restarting %UBUNTU_DISTRO%...
wsl.exe --terminate %UBUNTU_DISTRO% >nul 2>&1
set "UBUNTU_TERMINATE_RESULT=%ERRORLEVEL%"
if not "%UBUNTU_TERMINATE_RESULT%"=="0" goto :ubuntu_restart_failed

timeout /t 2 /nobreak >nul
call :timed_wsl_probe 45000
set "WSL_RETRY_RESULT=%ERRORLEVEL%"
if "%WSL_RETRY_RESULT%"=="0" goto :ubuntu_recovered
if "%WSL_RETRY_RESULT%"=="2" goto :ubuntu_still_unavailable
call :direct_wsl_probe
set "DIRECT_WSL_RESULT=%ERRORLEVEL%"
if "%DIRECT_WSL_RESULT%"=="0" goto :ubuntu_recovered
goto :ubuntu_still_unavailable

:cancelled_ubuntu_restart
echo.
echo %UBUNTU_DISTRO% was not restarted because you selected No.
echo No Ubuntu files or DL4MicEverywhere files were changed.
echo DL4MicEverywhere cannot continue until Ubuntu can execute a minimal command.
pause
exit /b 1

:ubuntu_restart_failed
echo.
echo Windows could not restart %UBUNTU_DISTRO% automatically.
echo WSL returned exit code %UBUNTU_TERMINATE_RESULT%.
echo No Ubuntu files or DL4MicEverywhere files were changed.
pause
exit /b 1

:ubuntu_still_unavailable
echo.
echo %UBUNTU_DISTRO% could not complete the WSL readiness check after restart.
if "%WSL_RETRY_RESULT%"=="2" echo Ubuntu did not finish starting within the 45-second safety limit.
if "%WSL_RETRY_RESULT%"=="1" echo Ubuntu started but the readiness command returned an error.
if "%WSL_RETRY_RESULT%"=="3" echo Windows could not start the WSL readiness command.
echo Last WSL recovery check returned exit code %WSL_RETRY_RESULT%.
echo.
echo No Ubuntu files or DL4MicEverywhere files were changed.
echo DL4MicEverywhere has already tried the bounded readiness probe, a direct
echo native WSL command, and the selected-distro restart path automatically.
echo.
echo If this persists, Windows is preventing this registered Ubuntu distro from
echo executing even a minimal command. The launcher will stop safely; the user is
echo not asked to run additional diagnostic commands in a terminal.
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

:offer_docker_start_for_integration
echo.
echo Docker Desktop is installed, but its Docker engine is not currently responding.
echo DL4MicEverywhere needs Docker Desktop running before it can verify whether
echo %UBUNTU_DISTRO% has WSL integration enabled.
echo.
call :ask_yes_no "Start Docker Desktop now?"
if errorlevel 1 goto :cancelled_docker_start_for_integration

echo.
echo Starting Docker Desktop...
call :start_docker_desktop
if not "%ERRORLEVEL%"=="0" goto :docker_desktop_not_ready

call :wait_for_windows_docker
if not "%ERRORLEVEL%"=="0" goto :docker_desktop_not_ready

echo Docker Desktop: ready.

rem Docker Desktop may need a few seconds after daemon startup to expose an
rem already-configured integration inside WSL. Try the distro again before
rem concluding that the integration setting is missing.
call :wait_for_docker_wsl_integration
if "%ERRORLEVEL%"=="0" (
    echo Docker integration: ready.
    goto :launch_application
)
goto :docker_windows_ready_for_integration

:cancelled_docker_start_for_integration
echo.
echo Docker Desktop was not started because you selected No.
echo No Docker Desktop settings were changed.
echo DL4MicEverywhere needs Docker Desktop running to continue.
pause
exit /b 1

:docker_desktop_not_ready
echo.
echo Docker Desktop could not become ready automatically.
echo No WSL integration setting will be changed while the Docker engine is unavailable.
echo.
echo Please start Docker Desktop manually and wait until it reports that the engine
echo is running, then run Windows_launch.bat again.
pause
exit /b 1

:cancelled_docker_wsl_integration
echo.
echo Docker integration was not changed because you selected No.
echo.
echo To enable it manually, open Docker Desktop and go to:
echo   Settings ^> Resources ^> WSL Integration
echo Then enable %UBUNTU_DISTRO% and select Apply.
pause
exit /b 1

:docker_wsl_integration_enable_failed
echo.
echo DL4MicEverywhere could not safely enable Docker Desktop WSL integration
echo automatically. No existing WSL integration entries were intentionally removed.
echo.
echo To enable it manually, open Docker Desktop and go to:
echo   Settings ^> Resources ^> WSL Integration
echo Then enable %UBUNTU_DISTRO% and select Apply.
echo.
if "%DOCKER_WSL_ENABLE_RESULT%"=="21" echo The Docker integration helper file was not found.
if "%DOCKER_WSL_ENABLE_RESULT%"=="22" echo Docker Desktop could not be stopped safely, so its settings were not edited.
if "%DOCKER_WSL_ENABLE_RESULT%"=="23" echo Docker Desktop settings could not be updated safely.
if "%DOCKER_WSL_ENABLE_RESULT%"=="24" echo Docker Desktop did not restart successfully after the attempted update.
echo Automatic integration step returned code %DOCKER_WSL_ENABLE_RESULT%.
pause
exit /b 1

:docker_wsl_integration_verify_failed
echo.
echo Docker Desktop was updated and restarted, but Docker is still not available
echo inside %UBUNTU_DISTRO%.
echo.
echo Please open Docker Desktop and confirm:
echo   Settings ^> Resources ^> WSL Integration
echo   %UBUNTU_DISTRO% is enabled
echo.
echo A backup of Docker Desktop's previous settings was kept next to its settings file
echo with the suffix .dl4mic-backup.
pause
exit /b 1

:launch_failed
echo.
echo DL4MicEverywhere did not start successfully inside %UBUNTU_DISTRO%.
echo The Linux launcher returned exit code %LAUNCH_RESULT%.
echo No additional changes will be made.
pause
exit /b 1
