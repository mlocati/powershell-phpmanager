Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
$ConfirmPreference = 'None'
$WarningPreference = 'Continue'
$InformationPreference = 'Continue'

# Get function definition files.
$scripts = @(Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -Depth 1) + @(Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -Depth 1)
foreach ($script in $scripts) {
    Write-Debug "Including $($script.FullName)"
    . $script.FullName
}
Export-ModuleMember -Function $scripts.Basename
