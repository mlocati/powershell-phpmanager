Write-Host "Setting up test dependencies"

Write-Host " - PowerShell edition: $($PSVersionTable.PSEdition)"
Write-Host " - PowerShell version: $($PSVersionTable.PSVersion.ToString())"
$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-Not($nuget)) {
    Write-Host ' - installing NuGet'
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    $nuget = Get-PackageProvider -Name NuGet
}
Write-Host " - NuGet version: $($nuget.Version.ToString())"

if ($PSVersionTable.PSEdition -ne 'Core') {
    $psScriptAnalyzer = Get-Module -Name PSScriptAnalyzer
    if (-Not($psScriptAnalyzer)) {
        $psScriptAnalyzer = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'PSScriptAnalyzer' }
        if ($psScriptAnalyzer -is [array]) {
            $psScriptAnalyzer = $psScriptAnalyzer[0]
        }
        if (-Not($psScriptAnalyzer)) {
            Write-Host ' - installing PSScriptAnalyzer'
            Install-Module -Name PSScriptAnalyzer -Force
            $psScriptAnalyzer = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'PSScriptAnalyzer' }
        }
    }
    Write-Host " - PSScriptAnalyzer version: $($psScriptAnalyzer.Version.ToString())"
}

$pester = Get-Module -Name Pester | Where-Object { $_.Version -ge '4.3' }
if (-Not($pester)) {
    $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' -and $_.Version -ge '4.3' }
    if ($pester -is [array]) {
        $pester = $pester[0]
    }
    if (-Not($pester)) {
        Write-Host ' - installing Pester'
        Install-Module -Name Pester -Force -SkipPublisherCheck
        $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' -and $_.Version -ge '4.3' }
    }
}
Write-Host " - Pester version: $($pester.Version.ToString())"
