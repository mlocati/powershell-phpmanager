param([string[]]$TestName)

New-Variable -Scope Global -Option ReadOnly -Name PHPMANAGER_FOLDER -Value (Split-Path -LiteralPath $PSScriptRoot | Join-Path -ChildPath PhpManager) -Force

Import-Module $Global:PHPMANAGER_FOLDER\PhpManager.psm1 -Force

Invoke-Pester -Script $PSScriptRoot\tests -TestName $TestName -PassThru  -OutputFile $PSScriptRoot\..\TestsResults.xml -OutputFormat NUnitXml
