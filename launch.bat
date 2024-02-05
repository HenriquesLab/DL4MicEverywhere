@ECHO OFF
:: Install Windows Subsytem for Linux
:: wsl.exe --install Ubuntu
wsl.exe -d Ubuntu bash -E launch.sh
pause