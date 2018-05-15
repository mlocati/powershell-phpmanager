FROM microsoft/windowsservercore:10.0.14393.2007

COPY *.dll C:/Windows/System32/

COPY setup.ps1 C:/

RUN powershell C:\setup.ps1
