param ([string[]]$TestName)

$Global:ProgressPreference = 'SilentlyContinue'

Import-Module -Name Pester -MinimumVersion 4.0

New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_MODULEPATH -Value (Split-Path -LiteralPath $PSScriptRoot | Join-Path -ChildPath PhpManager) -Force

New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_TESTPATH -Value $PSScriptRoot -Force

if (Test-Path Env:PM_TEST_DOCKER) {
    New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_TESTINSTALLS -Value 'C:\installs' -Force
} else {
    New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_TESTINSTALLS -Value (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath 'installs') -Force
}

Import-Module $Global:PHPMANAGER_MODULEPATH\PhpManager.psm1 -Force

Invoke-Pester -Script $PSScriptRoot\tests -TestName $TestName -PassThru -OutputFile $PSScriptRoot\..\TestsResults.xml -OutputFormat NUnitXml
