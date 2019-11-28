$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$version = '10.17.0-win-x64'
Invoke-WebRequest -Uri "https://nodejs.org/dist/v10.17.0/node-v$version.zip" -OutFile C:\nodejs.zip
Expand-Archive -LiteralPath C:\nodejs.zip -DestinationPath 'C:\Program Files'
Remove-Item -LiteralPath C:\nodejs.zip
Rename-Item -LiteralPath "C:\Program Files\node-v$version" -NewName 'C:\Program Files\NodeJS'
$newPath = "$Env:Path;C:\Program Files\NodeJS"
setx.exe Path $newPath /m
$Env:Path = $newPath
