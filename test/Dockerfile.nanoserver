FROM microsoft/nanoserver:10.0.14393.2007

COPY vcruntime140.dll C:/Windows/System32/

COPY setup.ps1 C:/

RUN powershell C:\setup.ps1
