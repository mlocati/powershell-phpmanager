param ([string[]]$TestName)

Import-Module -Name Pester -MinimumVersion 4.0

New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_MODULEPATH -Value (Split-Path -LiteralPath $PSScriptRoot | Join-Path -ChildPath PhpManager) -Force

New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_TESTPATH -Value $PSScriptRoot -Force

Import-Module $Global:PHPMANAGER_MODULEPATH\PhpManager.psm1 -Force

Invoke-Pester -Script $PSScriptRoot\tests -TestName $TestName -PassThru -OutputFile $PSScriptRoot\..\TestsResults.xml -OutputFormat NUnitXml
