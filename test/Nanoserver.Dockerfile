FROM microsoft/nanoserver:sac2016

COPY vcruntime140.dll C:/Windows/System32/

COPY setup.ps1 C:/

RUN powershell C:\setup.ps1
