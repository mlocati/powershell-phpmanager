@echo off
setlocal
docker.exe --version >NUL 2>NUL
if errorlevel 1 (
    echo Please install Docker for Windows. >&2
    exit /b 1
)

docker run --rm --volume "%~dp0..":/app --workdir /app/src mlocati/powershell-phpmanager-src:latest make
