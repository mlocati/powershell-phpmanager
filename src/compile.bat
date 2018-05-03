@echo off
setlocal
bash.exe --version >NUL 2>NUL
if errorlevel 1 (
    echo Please enable Windows Subsystem for Linux. >&2
    exit /b 1
)

cd /D "%~dp0"

bash -c "sh ./compile"
