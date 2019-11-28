$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$version = '10.17.0'
Invoke-WebRequest -Uri "https://nodejs.org/dist/v10.17.0/node-v$version-win-x64.zip" -OutFile C:\nodejs.zip
Expand-Archive -LiteralPath C:\nodejs.zip -DestinationPath 'C:\Program Files'
Remove-Item -LiteralPath C:\nodejs.zip
Rename-Item -LiteralPath "C:\Program Files\node-v$version-win-x64" -NewName 'C:\Program Files\NodeJS'
