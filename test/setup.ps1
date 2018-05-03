Write-Host "Setting up test dependencies"

Write-Host " - PowerShell version: $($PSVersionTable.PSVersion.ToString())"
$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
If (-Not($nuget)) {
    Write-Host ' - installing NuGet'
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    $nuget = Get-PackageProvider -Name NuGet
}
Write-Host " - NuGet version: $($nuget.Version.ToString())"

$psScriptAnalyzer = Get-Module -Name PSScriptAnalyzer
If (-Not($psScriptAnalyzer)) {
    $psScriptAnalyzer = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'PSScriptAnalyzer' }
    If ($psScriptAnalyzer -is [array]) {
        $psScriptAnalyzer = $psScriptAnalyzer[0]
    }
    If (-Not($psScriptAnalyzer)) {
        Write-Host ' - installing PSScriptAnalyzer'
        Install-Module -Name PSScriptAnalyzer -Force
        $psScriptAnalyzer = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'PSScriptAnalyzer' }
    }
}
Write-Host " - PSScriptAnalyzer version: $($psScriptAnalyzer.Version.ToString())"

$pester = Get-Module -Name Pester
If (-Not($pester)) {
    $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' }
    If ($pester -is [array]) {
        $pester = $pester[0]
    }
    If (-Not($pester)) {
        Write-Host ' - installing Pester'
        Install-Module -Name Pester -Force
        $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' }
    }
}
Write-Host " - Pester version: $($pester.Version.ToString())"
