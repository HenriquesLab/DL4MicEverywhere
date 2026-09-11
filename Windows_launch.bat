@echo off
setlocal EnableExtensions

rem =============================================================================
rem DL4MicEverywhere - Windows launcher
rem Simplified preflight revision 2
rem
rem   1. Check Docker Desktop is installed and running.
rem   2. Check WSL and discover an installed Ubuntu variant.
rem   3. Check that Ubuntu starts and can directly use Docker Desktop.
rem   4. Launch Linux_launch.sh / the GUI.
rem
rem No WSL cache, distro installation, WSL restart, Docker settings editing,
rem Docker Desktop integration repair, or PowerShell readiness wrapper is used.
rem =============================================================================

set "SCRIPT_PATH=%~dp0"
if "%SCRIPT_PATH:~-1%"=="\" set "SCRIPT_PATH=%SCRIPT_PATH:~0,-1%"
set "BASEDIR=%SCRIPT_PATH%"
set "DOCKER_DESKTOP_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\resources\bin\docker.exe"
set "WSL_UTF8=1"

cd /d "%BASEDIR%"

call :print_header

rem =============================================================================
rem 1. Docker Desktop
rem =============================================================================

echo [1/4] Checking Docker Desktop...

if not exist "%DOCKER_DESKTOP_EXE%" goto :docker_not_installed

if not exist "%DOCKER_EXE%" (
    set "DOCKER_EXE="
    for /f "delims=" %%D in ('where docker.exe 2^>nul') do if not defined DOCKER_EXE set "DOCKER_EXE=%%D"
)

if not defined DOCKER_EXE goto :docker_not_installed

"%DOCKER_EXE%" info >nul 2>&1
if "%ERRORLEVEL%"=="0" (
    echo       Docker Desktop: ready.
    goto :check_wsl
)

echo       Docker Desktop is installed but is not running yet.
echo       Starting Docker Desktop...
start "" "%DOCKER_DESKTOP_EXE%"

call :wait_for_docker
if not "%ERRORLEVEL%"=="0" goto :docker_not_ready

echo       Docker Desktop: ready.

rem =============================================================================
rem 2. WSL and Ubuntu discovery
rem =============================================================================

:check_wsl
echo.
echo [2/4] Checking Windows Subsystem for Linux and Ubuntu...

where wsl.exe >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :wsl_not_installed

wsl.exe --list --quiet >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :wsl_not_ready

set "UBUNTU_DISTRO="
for /f "delims=" %%D in ('wsl.exe --list --quiet 2^>nul ^| findstr /i /b /c:"Ubuntu"') do if not defined UBUNTU_DISTRO set "UBUNTU_DISTRO=%%D"

if not defined UBUNTU_DISTRO goto :ubuntu_not_found

echo       Ubuntu distribution found: %UBUNTU_DISTRO%

rem Root is used only for this tiny readiness probe so it does not depend on
rem the normal user's shell, profile, or systemd user session.
wsl.exe -d %UBUNTU_DISTRO% -u root --exec /bin/true >nul 2>&1
if not "%ERRORLEVEL%"=="0" goto :ubuntu_not_ready

echo       Ubuntu: ready.

rem =============================================================================
rem 3. Docker Desktop WSL integration
rem =============================================================================

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
rem Wait only when Docker Desktop was just started.
rem =============================================================================

:wait_for_docker
set /a DOCKER_WAIT_ATTEMPT=0

:wait_for_docker_loop
"%DOCKER_EXE%" info >nul 2>&1
if "%ERRORLEVEL%"=="0" exit /b 0

set /a DOCKER_WAIT_ATTEMPT+=1
if %DOCKER_WAIT_ATTEMPT% GEQ 30 exit /b 1

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
rem Clear failure messages
rem =============================================================================

:docker_not_installed
echo.
echo Docker Desktop was not found.
echo.
echo DL4MicEverywhere requires Docker Desktop for Windows.
echo Please install Docker Desktop, complete its normal Windows setup, and then
echo run Windows_launch.bat again.
echo.
pause
exit /b 1

:docker_not_ready
echo.
echo Docker Desktop was found, but its Docker engine did not become ready.
echo.
echo Please open Docker Desktop and wait until it reports that the engine is
echo running, then run Windows_launch.bat again.
echo.
pause
exit /b 1

:wsl_not_installed
echo.
echo Windows Subsystem for Linux was not found.
echo.
echo DL4MicEverywhere requires WSL and an Ubuntu distribution.
echo Please install Windows Subsystem for Linux and Ubuntu using the normal
echo Windows setup, restart Windows if requested, and then run this launcher again.
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
echo No Docker Desktop settings were changed by DL4MicEverywhere.
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
echo Windows launcher: Simplified preflight revision 2
echo ============================================================
exit /b 0
