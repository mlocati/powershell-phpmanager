Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Get function definition files.
$scripts = @(Get-ChildItem -Path $PSScriptRoot\*.ps1 -Depth 1)
ForEach ($script in $scripts) {
    Write-Verbose $('Including ' + $script.FullName)
    . $script.FullName
}
