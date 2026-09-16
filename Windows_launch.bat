@echo off
setlocal EnableExtensions

rem =============================================================================
rem DL4MicEverywhere - Windows launcher
rem WSL-first preflight with optional Ubuntu and per-user Docker Desktop installation.
rem
rem   1. Check WSL and discover/install a usable WSL 2 Ubuntu distribution.
rem   2. Discover Docker Desktop. If missing, offer Docker's supported per-user
rem      installation mode (no Windows Administrator privileges required).
rem   3. Check that Ubuntu can directly use Docker Desktop.
rem   4. Launch Linux_launch.sh / the GUI.
rem
rem The launcher itself stays non-elevated. If WSL must be installed or updated,
rem it asks for consent and elevates only Microsoft's WSL command through UAC.
rem Docker Desktop settings are never changed silently and Docker's license is
rem never accepted without explicit user consent.
rem =============================================================================

set "SCRIPT_PATH=%~dp0"
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
set "BASEDIR=%SCRIPT_PATH%"
set "WSL_UTF8=1"
set "DOCKER_DESKTOP_EXE="
set "DOCKER_EXE="
set "UBUNTU_DISTRO="
set "UBUNTU_USER="
set "PREFERRED_UBUNTU_DISTRO=Ubuntu-24.04"

cd /d "%BASEDIR%"

call :print_header

rem =============================================================================
rem 1. WSL and Ubuntu discovery. The launcher itself remains non-elevated. If
rem    WSL is missing or outdated, a dedicated helper asks for consent and uses
rem    UAC only for Microsoft's official install/update command.
rem =============================================================================

:check_wsl
echo [1/4] Checking Windows Subsystem for Linux and Ubuntu...

rem Current Docker Desktop requires WSL 2.1.5 or later for its WSL backend.
rem The helper distinguishes three important states:
rem   0 = modern WSL is ready, 2 = legacy/outdated WSL, 3 = WSL not installed.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\check_wsl_version.ps1"
set "WSL_VERSION_RESULT=%ERRORLEVEL%"
if "%WSL_VERSION_RESULT%"=="0" goto :query_wsl_distributions
if "%WSL_VERSION_RESULT%"=="2" goto :wsl_update_required
if "%WSL_VERSION_RESULT%"=="3" goto :wsl_not_installed
goto :wsl_detection_failed

:query_wsl_distributions
wsl.exe --list --quiet >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :wsl_not_ready

call :discover_ubuntu
if not defined UBUNTU_DISTRO goto :ubuntu_not_found

goto :verify_ubuntu

:verify_ubuntu
echo       Ubuntu distribution found: %UBUNTU_DISTRO%

rem Root is used only for this tiny readiness probe so it does not depend on
rem the normal user's shell, profile, or systemd user session.  Run the probe
rem from Linux / rather than inheriting the Windows launcher's current directory.
rem The PowerShell helper preserves WSL stderr so failures are diagnosable.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\wsl_readiness.ps1" -Action direct -Distro %UBUNTU_DISTRO%
set "UBUNTU_READINESS_RESULT=%ERRORLEVEL%"
if not "%UBUNTU_READINESS_RESULT%"=="0" goto :ubuntu_not_ready

rem Docker Desktop integration requires this exact distribution to use WSL 2.
rem Query WSL itself instead of inferring the generation from the Linux kernel
rem release string.  The helper normalizes WSL's Unicode/NUL output and returns:
rem   0 = WSL 2, 2 = WSL 1, 3 = distro not found, 4/10 = query/parse failure.
if not exist "%BASEDIR%\.tools\windows_tools\check_wsl_distribution_version.ps1" goto :wsl_version_helper_missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\check_wsl_distribution_version.ps1" -Distribution %UBUNTU_DISTRO%
set "UBUNTU_WSL_VERSION_RESULT=%ERRORLEVEL%"
if "%UBUNTU_WSL_VERSION_RESULT%"=="2" goto :ubuntu_convert_to_wsl2
if not "%UBUNTU_WSL_VERSION_RESULT%"=="0" goto :ubuntu_wsl_version_unknown

rem Resolve the configured non-root Linux account explicitly. Some WSL states
rem can retain a stale UID-1000 default even when the valid Ubuntu user has a
rem different UID (for example 1001), which can produce stale default-user relay errors.
if not exist "%BASEDIR%\.tools\windows_tools\discover_ubuntu_user.ps1" goto :ubuntu_user_helper_missing
call :discover_ubuntu_user
if not "%ERRORLEVEL%"=="0" goto :ubuntu_user_not_ready

echo       Ubuntu user: %UBUNTU_USER%
echo       Ubuntu: ready (WSL 2).
goto :check_docker

rem =============================================================================
rem 2. Docker Desktop discovery / optional per-user installation
rem =============================================================================

:check_docker
echo.
echo [2/4] Checking Docker Desktop...

call :discover_docker
if not defined DOCKER_DESKTOP_EXE goto :docker_not_installed
if not defined DOCKER_EXE goto :docker_not_installed

"%DOCKER_EXE%" info >nul 2>&1
if "%ERRORLEVEL%"=="0" (
    echo       Docker Desktop: ready.
    goto :check_docker_integration
)

echo       Docker Desktop is installed but is not running yet.
echo       Starting Docker Desktop...
start "" "%DOCKER_DESKTOP_EXE%"

call :wait_for_docker
if not "%ERRORLEVEL%"=="0" goto :docker_not_ready

echo       Docker Desktop: ready.
goto :check_docker_integration

:discover_ubuntu
set "UBUNTU_DISTRO="

rem Do not parse `wsl --list --quiet` directly in cmd.exe.  Some WSL/Windows
rem combinations expose embedded NUL/BOM characters when that output is piped,
rem producing a visually correct but invalid distribution name.  Normalize it
rem in PowerShell before returning a single ASCII-safe name to this launcher.
if not exist "%BASEDIR%\.tools\windows_tools\discover_ubuntu_wsl.ps1" exit /b 1
for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\discover_ubuntu_wsl.ps1" -PreferredDistribution %PREFERRED_UBUNTU_DISTRO%`) do if not defined UBUNTU_DISTRO set "UBUNTU_DISTRO=%%D"
exit /b 0

:discover_ubuntu_user
set "UBUNTU_USER="

rem Resolve the Linux username in PowerShell while probing the distribution as
rem root. The helper validates /etc/wsl.conf first and deliberately does not
rem assume that the normal account has UID 1000. It returns one ASCII-safe token.
for /f "usebackq delims=" %%U in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\discover_ubuntu_user.ps1" -Distribution %UBUNTU_DISTRO%`) do if not defined UBUNTU_USER set "UBUNTU_USER=%%U"
if not defined UBUNTU_USER exit /b 1
exit /b 0

:discover_docker
set "DOCKER_DESKTOP_EXE="
set "DOCKER_EXE="

rem Docker Desktop per-user installation (recommended by Docker).
if exist "%LOCALAPPDATA%\Programs\DockerDesktop\Docker Desktop.exe" set "DOCKER_DESKTOP_EXE=%LOCALAPPDATA%\Programs\DockerDesktop\Docker Desktop.exe"
if exist "%LOCALAPPDATA%\Programs\DockerDesktop\resources\bin\docker.exe" set "DOCKER_EXE=%LOCALAPPDATA%\Programs\DockerDesktop\resources\bin\docker.exe"

rem Traditional all-users installation.
if not defined DOCKER_DESKTOP_EXE if exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" set "DOCKER_DESKTOP_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
if not defined DOCKER_EXE if exist "C:\Program Files\Docker\Docker\resources\bin\docker.exe" set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"

rem Last-resort CLI discovery. A Desktop executable is still required because
rem DL4MicEverywhere needs Docker Desktop's WSL 2 backend on Windows.
if not defined DOCKER_EXE (
    for /f "delims=" %%D in ('where docker.exe 2^>nul') do if not defined DOCKER_EXE set "DOCKER_EXE=%%D"
)
exit /b 0

rem =============================================================================
rem Install Docker Desktop per-user if it is not present.
rem =============================================================================

:docker_not_installed
echo.
echo Docker Desktop was not found.
echo.
echo DL4MicEverywhere can install Docker Desktop for this Windows user only,
echo using Docker's WSL 2 backend. This per-user installation does not require
echo Administrator privileges. You will be asked to review and explicitly agree
echo to Docker's Subscription Service Agreement before anything is downloaded.
echo.

if not exist "%BASEDIR%\.tools\windows_tools\install_docker_desktop_per_user.ps1" goto :docker_install_helper_missing

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\install_docker_desktop_per_user.ps1"
set "DOCKER_INSTALL_RESULT=%ERRORLEVEL%"

if "%DOCKER_INSTALL_RESULT%"=="0" goto :docker_install_completed
if "%DOCKER_INSTALL_RESULT%"=="2" goto :docker_install_cancelled
if "%DOCKER_INSTALL_RESULT%"=="10" goto :docker_download_failed
if "%DOCKER_INSTALL_RESULT%"=="11" goto :docker_signature_invalid
if "%DOCKER_INSTALL_RESULT%"=="12" goto :docker_install_failed
if "%DOCKER_INSTALL_RESULT%"=="13" goto :docker_architecture_unsupported
goto :docker_install_failed

:docker_install_completed
echo.
echo       Docker Desktop installation completed. Rediscovering Docker...
call :discover_docker
if not defined DOCKER_DESKTOP_EXE goto :docker_installed_not_found
if not defined DOCKER_EXE goto :docker_installed_not_found

echo       Starting Docker Desktop...
start "" "%DOCKER_DESKTOP_EXE%"
call :wait_for_docker
if not "%ERRORLEVEL%"=="0" goto :docker_not_ready

echo       Docker Desktop: ready.
goto :check_docker_integration

rem =============================================================================
rem 3. Docker Desktop WSL integration
rem =============================================================================

:check_docker_integration
echo.
echo [3/4] Checking Docker Desktop integration with %UBUNTU_DISTRO%...

rem Docker Desktop WSL integration is installed at the distribution level. Probe
rem it as root first so this check is independent of the distro's normal-user UID
rem and avoids WSL's stale implicit-UID relay path. Then verify that the resolved
rem non-root account can also use Docker; the application itself runs as that user.
wsl.exe -d %UBUNTU_DISTRO% -u root --cd / --exec /usr/bin/env docker info >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :docker_wsl_integration_missing

if not exist "%BASEDIR%\.tools\windows_tools\ensure_ubuntu_docker_user_access.ps1" goto :docker_user_access_helper_missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\ensure_ubuntu_docker_user_access.ps1" -Distribution %UBUNTU_DISTRO% -User %UBUNTU_USER%
set "DOCKER_USER_ACCESS_RESULT=%ERRORLEVEL%"
if "%DOCKER_USER_ACCESS_RESULT%"=="0" goto :docker_integration_ready
if "%DOCKER_USER_ACCESS_RESULT%"=="2" goto :docker_user_access_cancelled
if "%DOCKER_USER_ACCESS_RESULT%"=="3" goto :docker_wsl_integration_missing
goto :docker_user_access_failed

:docker_integration_ready
echo       Docker integration: ready for %UBUNTU_USER%.

rem =============================================================================
rem 4. Launch DL4MicEverywhere
rem =============================================================================

:launch_application
echo.
echo [4/4] Starting DL4MicEverywhere using %UBUNTU_DISTRO%...
echo.

wsl.exe -d %UBUNTU_DISTRO% -u %UBUNTU_USER% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1 /bin/bash -E Linux_launch.sh
set "LAUNCH_RESULT=%ERRORLEVEL%"

if "%LAUNCH_RESULT%"=="0" exit /b 0
if "%LAUNCH_RESULT%"=="42" goto :complete_uninstall
if "%LAUNCH_RESULT%"=="90" goto :restart_later
if "%LAUNCH_RESULT%"=="91" goto :restart_scheduled

goto :launch_failed

rem =============================================================================
rem Wait only when Docker Desktop was just started. Fresh first launch can take
rem longer than a normal restart, so allow up to two minutes.
rem =============================================================================

:wait_for_docker
set /a DOCKER_WAIT_ATTEMPT=0

:wait_for_docker_loop
"%DOCKER_EXE%" info >nul 2>&1
if "%ERRORLEVEL%"=="0" exit /b 0

set /a DOCKER_WAIT_ATTEMPT+=1
if %DOCKER_WAIT_ATTEMPT% GEQ 60 exit /b 1

timeout /t 2 /nobreak >nul
goto :wait_for_docker_loop

rem =============================================================================
rem Normal uninstall handoff from Linux_launch.sh
rem =============================================================================

:complete_uninstall
echo.
echo DL4MicEverywhere is ready to be removed.
echo The DL4MicEverywhere application folder will now be deleted.

set "DL4ME_UNINSTALL_DIR=%BASEDIR%"
cd /d "%TEMP%"
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 750; Remove-Item -LiteralPath $env:DL4ME_UNINSTALL_DIR -Recurse -Force" >nul 2>&1
exit /b 0

rem =============================================================================
rem Clear prerequisite / installation messages
rem =============================================================================

:wsl_not_installed
echo.
echo Windows Subsystem for Linux is not installed or its Windows components are not
echo enabled yet.
echo.
echo DL4MicEverywhere can install WSL automatically using Microsoft's official
echo installer. Windows will request Administrator permission because enabling WSL 2
echo can require machine-level virtualization components. Only Microsoft's WSL
echo command is elevated; DL4MicEverywhere itself remains a normal user process.
echo.

if not exist "%BASEDIR%\.tools\windows_tools\install_or_update_wsl.ps1" goto :wsl_install_helper_missing

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\install_or_update_wsl.ps1" -Operation Install
set "WSL_PREREQUISITE_RESULT=%ERRORLEVEL%"
if "%WSL_PREREQUISITE_RESULT%"=="0" goto :check_wsl
if "%WSL_PREREQUISITE_RESULT%"=="2" goto :wsl_install_cancelled
if "%WSL_PREREQUISITE_RESULT%"=="10" goto :wsl_install_failed
if "%WSL_PREREQUISITE_RESULT%"=="11" goto :wsl_install_unsupported
if "%WSL_PREREQUISITE_RESULT%"=="12" goto :wsl_restart_required
if "%WSL_PREREQUISITE_RESULT%"=="13" goto :wsl_version_still_too_old
if "%WSL_PREREQUISITE_RESULT%"=="20" goto :wsl_restart_scheduled
goto :wsl_install_failed

:wsl_update_required
echo.
echo The installed Windows Subsystem for Linux is older than the version required by
echo Docker Desktop.
echo.
echo DL4MicEverywhere can update WSL automatically using Microsoft's official
echo updater. Windows may request Administrator permission; only the WSL update
echo command is elevated.
echo.

if not exist "%BASEDIR%\.tools\windows_tools\install_or_update_wsl.ps1" goto :wsl_install_helper_missing

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\install_or_update_wsl.ps1" -Operation Update
set "WSL_PREREQUISITE_RESULT=%ERRORLEVEL%"
if "%WSL_PREREQUISITE_RESULT%"=="0" goto :check_wsl
if "%WSL_PREREQUISITE_RESULT%"=="2" goto :wsl_update_cancelled
if "%WSL_PREREQUISITE_RESULT%"=="10" goto :wsl_update_failed
if "%WSL_PREREQUISITE_RESULT%"=="11" goto :wsl_install_unsupported
if "%WSL_PREREQUISITE_RESULT%"=="12" goto :wsl_restart_required
if "%WSL_PREREQUISITE_RESULT%"=="13" goto :wsl_version_still_too_old
if "%WSL_PREREQUISITE_RESULT%"=="20" goto :wsl_restart_scheduled
goto :wsl_update_failed

:wsl_detection_failed
echo.
echo DL4MicEverywhere could not determine the Windows Subsystem for Linux state.
echo.
echo Please run "wsl --version" and "wsl --status" in PowerShell or Command Prompt
echo to inspect the WSL installation, then run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_install_cancelled
echo.
echo WSL installation was cancelled. No Windows WSL installation was started.
echo You can run Windows_launch.bat again whenever you are ready.
echo.
pause
exit /b 0

:wsl_update_cancelled
echo.
echo WSL update was cancelled. DL4MicEverywhere requires WSL 2.1.5 or later.
echo You can run Windows_launch.bat again whenever you are ready.
echo.
pause
exit /b 0

:wsl_install_failed
echo.
echo The automatic Windows Subsystem for Linux installation did not complete.
echo DL4MicEverywhere used Microsoft's official "wsl --install --no-distribution"
echo path and also offered the --web-download fallback when appropriate.
echo.
echo Review any message shown by Windows, then run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_update_failed
echo.
echo The automatic Windows Subsystem for Linux update did not complete.
echo DL4MicEverywhere used Microsoft's official "wsl --update" command and also
echo offered the --web-download fallback when appropriate.
echo.
echo Review any message shown by Windows, then run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_install_unsupported
echo.
echo This Windows installation does not provide a usable wsl.exe installer command.
echo Automatic WSL installation is therefore not available on this Windows version.
echo.
echo Please install all current Windows updates and try Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_restart_required
echo.
echo The WSL installation/update completed, but Windows must restart before WSL 2 is
echo ready. You chose not to restart automatically, or Windows could not schedule
echo the restart.
echo.
echo Please restart Windows, then run Windows_launch.bat again.
echo.
pause
exit /b 0

:wsl_restart_scheduled
echo.
echo WSL installation/update completed and a Windows restart was requested.
echo After Windows restarts, run Windows_launch.bat again to continue setup.
echo.
exit /b 0

:wsl_version_still_too_old
echo.
echo WSL was installed/updated successfully, but the detected version is still older
echo than the Docker Desktop requirement of WSL 2.1.5.
echo.
echo Install all pending Windows updates and run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_install_helper_missing
echo.
echo The DL4MicEverywhere WSL installation/update helper is missing from this copy
echo of the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:wsl_not_ready
echo.
echo Windows Subsystem for Linux is installed, but Windows could not query its
echo distributions successfully.
echo.
echo Please open WSL or Ubuntu once from the Windows Start menu and complete any
echo pending Windows/Ubuntu setup, then run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_not_found
echo.
echo Windows Subsystem for Linux is available, but no Ubuntu distribution was found.
echo.
echo DL4MicEverywhere can install %PREFERRED_UBUNTU_DISTRO% automatically using
echo Microsoft's official WSL installation mechanism.
echo.

if not exist "%BASEDIR%\.tools\windows_tools\install_ubuntu_wsl.ps1" goto :ubuntu_install_helper_missing

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\install_ubuntu_wsl.ps1" -Distribution %PREFERRED_UBUNTU_DISTRO%
set "UBUNTU_INSTALL_RESULT=%ERRORLEVEL%"

if "%UBUNTU_INSTALL_RESULT%"=="0" goto :ubuntu_install_completed
if "%UBUNTU_INSTALL_RESULT%"=="2" goto :ubuntu_install_cancelled
if "%UBUNTU_INSTALL_RESULT%"=="10" goto :ubuntu_distribution_unavailable
if "%UBUNTU_INSTALL_RESULT%"=="11" goto :ubuntu_install_failed
if "%UBUNTU_INSTALL_RESULT%"=="12" goto :ubuntu_installed_not_found
if "%UBUNTU_INSTALL_RESULT%"=="13" goto :ubuntu_initial_setup_failed
if "%UBUNTU_INSTALL_RESULT%"=="14" goto :ubuntu_wsl2_configuration_failed
if "%UBUNTU_INSTALL_RESULT%"=="15" goto :ubuntu_install_failed
goto :ubuntu_install_failed

:ubuntu_install_completed
echo.
echo       Ubuntu installation completed. Verifying %PREFERRED_UBUNTU_DISTRO%...
rem The installer just registered this exact distribution name, so avoid an
rem unnecessary list/parse round-trip before the first verification.  Normal
rem subsequent launches still use the normalized discovery helper above.
set "UBUNTU_DISTRO=%PREFERRED_UBUNTU_DISTRO%"
goto :verify_ubuntu

:ubuntu_install_cancelled
echo.
echo Ubuntu installation was cancelled. No Ubuntu distribution was installed.
echo You can run Windows_launch.bat again whenever you are ready.
echo.
pause
exit /b 0

:ubuntu_distribution_unavailable
echo.
echo %PREFERRED_UBUNTU_DISTRO% could not be found in the WSL online distribution catalog.
echo Check your internet connection and confirm that WSL can list online distributions:
echo.
echo     wsl --list --online
echo.
echo Then run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_install_failed
echo.
echo The automatic %PREFERRED_UBUNTU_DISTRO% installation did not complete successfully.
echo.
echo You can retry Windows_launch.bat or install it manually with:
echo.
echo     wsl --install -d %PREFERRED_UBUNTU_DISTRO%
echo.
pause
exit /b 1

:ubuntu_installed_not_found
echo.
echo WSL reported a successful Ubuntu installation, but DL4MicEverywhere could not
echo find the registered %PREFERRED_UBUNTU_DISTRO% distribution afterwards.
echo.
echo Run "wsl --list --verbose" to inspect the registered distributions and then
echo run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_initial_setup_failed
echo.
echo %PREFERRED_UBUNTU_DISTRO% was installed, but its first-run Linux user setup did
echo not complete successfully.
echo.
echo Start %PREFERRED_UBUNTU_DISTRO% once, create the requested Linux username and
echo password, close the Ubuntu shell, and then run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_wsl2_configuration_failed
echo.
echo %PREFERRED_UBUNTU_DISTRO% was installed, but Windows could not configure it
echo as WSL 2 automatically.
echo.
echo Inspect the registered version with:
echo.
echo     wsl --list --verbose
echo.
echo If it shows VERSION 1, convert it with:
echo.
echo     wsl --set-version %PREFERRED_UBUNTU_DISTRO% 2
echo.
pause
exit /b 1

:ubuntu_install_helper_missing
echo.
echo The DL4MicEverywhere Ubuntu installation helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:ubuntu_not_ready
echo.
echo The Ubuntu distribution %UBUNTU_DISTRO% is installed, but the WSL readiness
echo probe did not complete successfully.
echo.
if exist "%TEMP%\dl4me_wsl_probe_stderr.txt" (
    echo WSL reported:
    echo ------------------------------------
    type "%TEMP%\dl4me_wsl_probe_stderr.txt"
    echo ------------------------------------
    echo.
)
echo Confirm that %UBUNTU_DISTRO% opens normally and that its one-time Linux user
echo setup has completed. The diagnostic above should identify the underlying WSL
echo error if the distribution itself is already usable.
echo.
pause
exit /b 1

:ubuntu_user_not_ready
echo.
echo The Ubuntu distribution %UBUNTU_DISTRO% is installed, but DL4MicEverywhere
echo could not resolve a usable non-root Linux account for it.
echo.
echo DL4MicEverywhere does not assume that the account must have UID 1000. It first
echo checks the [user] default entry in /etc/wsl.conf and then validates the account.
echo.
echo Inspect the configured account with:
echo.
echo     wsl -d %UBUNTU_DISTRO% -u root -- cat /etc/wsl.conf
echo     wsl -d %UBUNTU_DISTRO% -u root -- cat /etc/passwd
echo.
echo If /etc/wsl.conf names a valid user, confirm it can start with:
echo.
echo     wsl -d %UBUNTU_DISTRO% -u YOUR_USERNAME -- id
echo.
pause
exit /b 1

:ubuntu_user_helper_missing
echo.
echo The DL4MicEverywhere Ubuntu user-discovery helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:ubuntu_convert_to_wsl2
echo.
echo The Ubuntu distribution %UBUNTU_DISTRO% is registered as WSL 1.
echo DL4MicEverywhere requires WSL 2 for Docker Desktop integration.
echo.
if not exist "%BASEDIR%\.tools\windows_tools\convert_wsl_distribution_to_v2.ps1" goto :wsl_conversion_helper_missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\convert_wsl_distribution_to_v2.ps1" -Distribution %UBUNTU_DISTRO%
set "UBUNTU_WSL_CONVERSION_RESULT=%ERRORLEVEL%"
if "%UBUNTU_WSL_CONVERSION_RESULT%"=="0" goto :verify_ubuntu
if "%UBUNTU_WSL_CONVERSION_RESULT%"=="2" goto :ubuntu_wsl2_conversion_cancelled
goto :ubuntu_wsl2_conversion_failed

:ubuntu_wsl2_conversion_cancelled
echo.
echo WSL 2 conversion was cancelled. DL4MicEverywhere cannot use Docker Desktop
echo with %UBUNTU_DISTRO% while it remains on WSL 1.
echo.
pause
exit /b 0

:ubuntu_wsl2_conversion_failed
echo.
echo Windows could not convert %UBUNTU_DISTRO% to WSL 2 automatically.
echo.
echo You can inspect the distribution state with:
echo.
echo     wsl --list --verbose
echo.
echo and retry the conversion manually with:
echo.
echo     wsl --set-version %UBUNTU_DISTRO% 2
echo.
pause
exit /b 1

:wsl_conversion_helper_missing
echo.
echo The DL4MicEverywhere WSL conversion helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:ubuntu_wsl_version_unknown
echo.
echo DL4MicEverywhere could start %UBUNTU_DISTRO%, but could not determine whether
echo that distribution is WSL 1 or WSL 2 using "wsl --list --verbose".
echo.
echo Please run the following command in PowerShell or Command Prompt to inspect it:
echo.
echo     wsl --list --verbose
echo.
echo If %UBUNTU_DISTRO% shows VERSION 2, this is a launcher detection error.
echo.
pause
exit /b 1

:wsl_version_helper_missing
echo.
echo The DL4MicEverywhere WSL version-check helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:docker_install_cancelled
echo.
echo Docker Desktop installation was cancelled. No Docker software was installed.
echo You can run Windows_launch.bat again whenever you are ready.
echo.
pause
exit /b 0

:docker_download_failed
echo.
echo Docker Desktop could not be downloaded from Docker's official HTTPS server.
echo Check your internet connection, VPN/proxy settings, and security software,
echo then run Windows_launch.bat again.
echo.
pause
exit /b 1

:docker_signature_invalid
echo.
echo The downloaded Docker Desktop installer did not pass Windows Authenticode
echo signature validation. For safety, DL4MicEverywhere did not run it.
echo.
echo Please download Docker Desktop manually from Docker's official website or try
echo again later. Do not bypass this validation.
echo.
pause
exit /b 1

:docker_install_failed
echo.
echo Docker Desktop per-user installation did not complete successfully.
echo.
echo If Docker created an installer log, it is normally located at:
echo     %LOCALAPPDATA%\Docker\install-log.txt
echo.
echo You can inspect that log or install Docker Desktop manually, then run this
echo launcher again.
echo.
pause
exit /b 1

:docker_installed_not_found
echo.
echo Docker Desktop reported a successful installation, but DL4MicEverywhere could
echo not find the installed application or Docker CLI afterwards.
echo.
echo Expected per-user location:
echo     %LOCALAPPDATA%\Programs\DockerDesktop
echo.
echo Please start Docker Desktop once from the Windows Start menu and rerun this
echo launcher. If it is not present, reinstall Docker Desktop manually.
echo.
pause
exit /b 1

:docker_architecture_unsupported
echo.
echo DL4MicEverywhere cannot automatically select a Docker Desktop installer for
echo this Windows processor architecture.
echo.
echo Please install the appropriate Docker Desktop build manually and then rerun
echo Windows_launch.bat.
echo.
pause
exit /b 1

:docker_install_helper_missing
echo.
echo The DL4MicEverywhere Docker installation helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:docker_not_ready
echo.
echo Docker Desktop was found, but its Docker engine did not become ready within
echo two minutes.
echo.
echo Please open Docker Desktop and review any message it displays. Once Docker
echo reports that the engine is running, run Windows_launch.bat again.
echo.
pause
exit /b 1

:docker_user_access_cancelled
echo.
echo Docker Desktop and WSL integration are running, but the Ubuntu account
echo %UBUNTU_USER% does not currently have permission to use the Docker socket.
echo.
echo No Linux group membership was changed. Run Windows_launch.bat again if you
echo want DL4MicEverywhere to offer the Docker access repair again.
echo.
pause
exit /b 0

:docker_user_access_failed
echo.
echo Docker Desktop is running and works inside %UBUNTU_DISTRO% as root, but
echo DL4MicEverywhere could not safely make Docker available to Ubuntu user:
echo.
echo     %UBUNTU_USER%
echo.
echo The automatic repair only handles the standard Docker socket configuration
echo where /var/run/docker.sock is owned by group "docker". It does not broaden
echo socket permissions or add your account to unrelated privileged groups.
echo.
echo From PowerShell, these commands can help diagnose the current state:
echo.
echo     wsl -d %UBUNTU_DISTRO% -u root -- ls -l /var/run/docker.sock
echo     wsl -d %UBUNTU_DISTRO% -u root -- getent group docker
echo     wsl -d %UBUNTU_DISTRO% -u %UBUNTU_USER% -- id
echo     wsl -d %UBUNTU_DISTRO% -u %UBUNTU_USER% -- docker info
echo.
pause
exit /b 1

:docker_user_access_helper_missing
echo.
echo The DL4MicEverywhere Docker user-access helper is missing from this copy of
echo the repository. Please download a complete DL4MicEverywhere release and try again.
echo.
pause
exit /b 1

:docker_wsl_integration_missing
echo.
echo Docker Desktop is running, but Docker cannot be used from:
echo.
echo     %UBUNTU_DISTRO%
echo.
echo Enable this distribution in Docker Desktop:
echo.
echo   1. Open Docker Desktop.
echo   2. Open Settings ^(gear icon^).
echo   3. Select Resources ^> WSL Integration.
echo   4. Under "Enable integration with additional distros", enable:
echo.
echo          %UBUNTU_DISTRO%
echo.
echo   5. Select Apply / Apply ^& Restart if shown.
echo   6. Wait until Docker Desktop reports that the engine is running.
echo   7. Run Windows_launch.bat again.
echo.
echo No Docker Desktop settings were changed automatically by DL4MicEverywhere.
echo.
pause
exit /b 1

:restart_later
echo.
echo DL4MicEverywhere dependencies were installed successfully.
echo You chose to restart later. Please restart Windows before running
echo DL4MicEverywhere again.
echo.
pause
exit /b 0

:restart_scheduled
echo.
echo DL4MicEverywhere dependencies were installed successfully.
echo A Windows restart was requested successfully.
echo.
exit /b 0

:launch_failed
echo.
echo DL4MicEverywhere ended unexpectedly inside %UBUNTU_DISTRO%.
echo The Linux launcher returned exit code %LAUNCH_RESULT%.
echo.
echo The Windows preflight checks all passed, so this error came from the Linux
echo launcher rather than Docker Desktop / WSL detection.
echo.
pause
exit /b %LAUNCH_RESULT%

:print_header
echo ============================================================
echo DL4MicEverywhere
echo Windows launcher: WSL-first Ubuntu and Docker Desktop preflight
echo ============================================================
exit /b 0
