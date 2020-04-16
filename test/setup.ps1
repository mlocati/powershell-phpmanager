Write-Host "Setting up test dependencies"
$pcInfo = Get-ComputerInfo
Write-Host " - Windows installation type: $($pcInfo.WindowsInstallationType)"
Write-Host " - Windows version name: $($pcInfo.WindowsProductName)"
Write-Host " - PowerShell edition: $($PSVersionTable.PSEdition)"
Write-Host " - PowerShell version: $($PSVersionTable.PSVersion.ToString())"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
  Write-Host 'Failed to configure TLS1.2 for ServicePointManager'
  Write-Host $_
}

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
    $vcRedist = Get-Module -Name VcRedist
    if (-Not($vcRedist)) {
        $vcRedist = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'VcRedist' }
        if ($vcRedist -is [array]) {
            $vcRedist = $vcRedist[0]
        }
        if (-Not($vcRedist)) {
            Write-Host ' - installing VcRedist'
            Install-Module -Name VcRedist -Force
            $vcRedist = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'VcRedist' }
        }
    }
    Write-Host " - VcRedist version: $($vcRedist.Version.ToString())"
}

$pester = Get-Module -Name Pester | Where-Object { $_.Version -ge '4.5' }
if (-Not($pester)) {
    $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' -and $_.Version -ge '4.5' }
    if ($pester -is [array]) {
        $pester = $pester[0]
    }
    if (-Not($pester)) {
        Write-Host ' - installing Pester'
        Install-Module -Name Pester -Force -SkipPublisherCheck
        $pester = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'Pester' -and $_.Version -ge '4.5' }
    }
}
Write-Host " - Pester version: $($pester.Version.ToString())"
