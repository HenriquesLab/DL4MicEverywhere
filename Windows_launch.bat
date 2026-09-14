@echo off
setlocal EnableExtensions

rem =============================================================================
rem DL4MicEverywhere - Windows launcher
rem WSL-first preflight with optional per-user Docker Desktop installation.
rem
rem   1. Check WSL and discover a usable WSL 2 Ubuntu distribution.
rem   2. Discover Docker Desktop. If missing, offer Docker's supported per-user
rem      installation mode (no Windows Administrator privileges required).
rem   3. Check that Ubuntu can directly use Docker Desktop.
rem   4. Launch Linux_launch.sh / the GUI.
rem
rem The launcher does not enable Windows optional features, elevate itself, edit
rem Docker Desktop settings, or silently accept Docker's license agreement.
rem =============================================================================

set "SCRIPT_PATH=%~dp0"
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
set "BASEDIR=%SCRIPT_PATH%"
set "WSL_UTF8=1"
set "DOCKER_DESKTOP_EXE="
set "DOCKER_EXE="
set "UBUNTU_DISTRO="

cd /d "%BASEDIR%"

call :print_header

rem =============================================================================
rem 1. WSL and Ubuntu discovery. Docker's per-user WSL 2 install assumes WSL is
rem    already enabled; enabling WSL for the first time is a machine-level step.
rem =============================================================================

:check_wsl
echo [1/4] Checking Windows Subsystem for Linux and Ubuntu...

where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :wsl_not_installed

rem Current Docker Desktop requires WSL 2.1.5 or later for its WSL backend.
rem If --version is unavailable, the inbox WSL installation is too old for the
rem modern per-user Docker Desktop path and should be updated first.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BASEDIR%\.tools\windows_tools\check_wsl_version.ps1"
set "WSL_VERSION_RESULT=%ERRORLEVEL%"
if "%WSL_VERSION_RESULT%"=="2" goto :wsl_update_required
if not "%WSL_VERSION_RESULT%"=="0" goto :wsl_update_required

wsl.exe --list --quiet >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :wsl_not_ready

for /f "delims=" %%D in ('wsl.exe --list --quiet 2^>nul ^| findstr /i /b /c:"Ubuntu"') do if not defined UBUNTU_DISTRO set "UBUNTU_DISTRO=%%D"

if not defined UBUNTU_DISTRO goto :ubuntu_not_found

echo       Ubuntu distribution found: %UBUNTU_DISTRO%

rem Root is used only for this tiny readiness probe so it does not depend on
rem the normal user's shell, profile, or systemd user session.
wsl.exe -d %UBUNTU_DISTRO% -u root --exec /bin/true >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :ubuntu_not_ready

rem Docker Desktop's distro integration requires WSL 2. Modern WSL 2 kernels
rem contain microsoft-standard/WSL2 in the kernel release string; WSL 1 does not.
wsl.exe -d %UBUNTU_DISTRO% -u root --exec /bin/grep -Eqi "microsoft-standard|WSL2" /proc/sys/kernel/osrelease >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :ubuntu_not_wsl2

echo       Ubuntu: ready (WSL 2).

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

rem Important: invoke Docker directly. Do not go through sh -lc / bash -lc.
rem This avoids shell quoting, login-shell configuration, and systemd-user-session
rem side effects from being mistaken for a Docker Desktop integration failure.
wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env docker info >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :docker_wsl_integration_missing

echo       Docker integration: ready.

rem =============================================================================
rem 4. Launch DL4MicEverywhere
rem =============================================================================

:launch_application
echo.
echo [4/4] Starting DL4MicEverywhere using %UBUNTU_DISTRO%...
echo.

wsl.exe -d %UBUNTU_DISTRO% --exec /usr/bin/env DL4ME_WINDOWS_WRAPPER=1 /bin/bash -E Linux_launch.sh
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
echo Windows Subsystem for Linux was not found.
echo.
echo DL4MicEverywhere requires WSL 2 and an Ubuntu distribution before Docker
echo Desktop can be installed automatically. Enabling WSL 2 for the first time is
echo a Windows machine-level operation and may require Administrator privileges.
echo Please install WSL and Ubuntu using the normal Windows setup, restart Windows
echo if requested, and then run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_update_required
echo.
echo The installed Windows Subsystem for Linux is too old for the current Docker
echo Desktop WSL 2 backend, or its version could not be determined.
echo.
echo Docker Desktop currently requires WSL 2.1.5 or later. Please update WSL from
echo an Administrator PowerShell/Command Prompt using:
echo.
echo     wsl --update
echo.
echo Restart Windows if requested, then run Windows_launch.bat again.
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
echo Please install an Ubuntu distribution for WSL, complete its initial setup,
echo and then run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_not_ready
echo.
echo The Ubuntu distribution "%UBUNTU_DISTRO%" is installed, but WSL could not
echo start it successfully.
echo.
echo Please open %UBUNTU_DISTRO% once from the Windows Start menu and complete any
echo first-run Ubuntu setup that appears. Then run Windows_launch.bat again.
echo.
pause
exit /b 1

:ubuntu_not_wsl2
echo.
echo The Ubuntu distribution "%UBUNTU_DISTRO%" does not appear to be running as
echo WSL 2. Docker Desktop integration with DL4MicEverywhere requires WSL 2.
echo.
echo From an Administrator PowerShell/Command Prompt, convert it with:
echo.
echo     wsl --set-version "%UBUNTU_DISTRO%" 2
echo.
echo Then run Windows_launch.bat again.
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
echo Windows launcher: WSL-first per-user Docker Desktop preflight
echo ============================================================
exit /b 0
