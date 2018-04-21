@echo off
setlocal EnableDelayedExpansion

call :searchCSC csc.exe "%ProgramFiles(x86)%\MSBuild\14.0\Bin\csc.exe" "%ProgramFiles%\MSBuild\14.0\Bin\csc.exe"
if errorlevel 1 (
	echo Unable to find csc.exe>&2
	exit /b 1
)

set CSC_OPTIONS=/target:exe /debug- /optimize+ /warnaserror+ /checked+ /unsafe- /nologo /noconfig /reference:System.dll /nostdlib-
set SRC_FILE="%~dp0Inspect-PhpExtension.cs"
set DST_FOLDER=%~dp0..\PhpManager\private\bin
echo Compiling for x86...
%CSC% %CSC_OPTIONS% /platform:x86 /out:"%DST_FOLDER%/Inspect-PhpExtension-x86.exe" %SRC_FILE%
if errorlevel 1 exit /b 1
echo Compiling for x64...
%CSC% %CSC_OPTIONS% /platform:x64 /out:"%DST_FOLDER%/Inspect-PhpExtension-x64.exe" %SRC_FILE%
if errorlevel 1 exit /b 1
echo Done.

:searchCSC
for %%i in (%*) do (
	if exist %%i (
		set CSC=%%i
		exit /b 0
	)
)
exit /b 1
