FROM microsoft/nanoserver:sac2016

COPY test/setup.ps1 C:/

RUN powershell C:\setup.ps1
