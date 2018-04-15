<#
Module to manage PHP installations and PHP extensions.

Copyright (c) Michele Locati, 2018

Source: https://github.com/mlocati/powershell-php

License: MIT - see https://github.com/mlocati/powershell-php/blob/master/LICENSE
#>
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction']='Stop'

New-Variable -Option Constant -Scope Script -Name 'URL_QA' -Value 'https://windows.php.net/downloads/releases/archives/'
New-Variable -Option Constant -Scope Script -Name 'URL_RELEASES' -Value 'https://windows.php.net/downloads/releases/'
New-Variable -Option Constant -Scope Script -Name 'URL_ARCHIVES' -Value 'https://windows.php.net/downloads/releases/archives/'

New-Variable -Option Constant -Scope Script -Name 'RX_ZIPARCHIVE' -Value 'php-(\d+\.\d+\.\d+)(?:RC([1-9]\d*))?(-nts)?-Win32-VC(\d{1,2})-(x86|x64)\.zip'

enum PhpReleaseState {
    Unknown = 0
    QA = 1
    Release = 2
    Archive = 3
}

class PhpVersion {
    [string] $Version
    [string] $RC
    [int] $Bits
    [bool] $ThreadSafe
    [int] $VCVersion
    [PhpReleaseState] $ReleaseState
    [string] $DownloadUrl
    [string] $ExeFullPath
    [string] GetFullVersion() {
        if ($this.RC -eq '') {
            return $this.Version
        }
        return $this.Version + 'RC' + $this.RC
    }
    [string] DescribeVersion() {
        $Result = $this.GetFullVersion()
        $Result += ' ' + [string]$this.Bits + '-bit'
        if ($this.ThreadSafe) {
            $Result += ' Thread-Safe'
        } else {
            $Result += ' Non-Thread-Safe'
        }
        return $Result
    }
    static [PhpVersion] FromUrl([String] $PageUrl, [String] $Url, [PhpReleaseState] $ReleaseState) {
        [PhpVersion] $Result = New-Object PhpVersion
        $RxMatch = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        $Result.Version = $RxMatch.Matches.Groups[1].Value
        $Result.RC = if ($RxMatch.Matches.Groups[2].Value -eq '') { '' } else { [string][int] $RxMatch.Matches.Groups[2].Value }
        $Result.Bits = if ($RxMatch.Matches.Groups[5].Value -eq 'x64') { 64 } else { 32 }
        $Result.ThreadSafe = $RxMatch.Matches.Groups[3].Value -ne '-nts'
        $Result.VCVersion = [int] $RxMatch.Matches.Groups[4].Value
        $Result.ReleaseState = $ReleaseState
        $Result.DownloadUrl = [Uri]::new([Uri]$PageUrl, $Url).AbsoluteUri
        $Result.ExeFullPath = ''
        return $Result
    }
    static [PhpVersion] FromExecutable([String] $ExecutablePath) {
        [PhpVersion] $Result = New-Object PhpVersion
        $ExeParameters = @('-r', 'echo PHP_VERSION, ''@'', PHP_INT_SIZE * 8;')
        $ExeResult = & $ExecutablePath $ExeParameters
        $RxMatch = $ExeResult | Select-String -CaseSensitive -Pattern '^(\d+\.\d+\.\d+)(?:RC(\d+))?@(\d+)$'
        $Result.Version = $RxMatch.Matches.Groups[1].Value
        $Result.RC = if ($RxMatch.Matches.Groups[2].Value -eq '') { '' } else { [string][int] $RxMatch.Matches.Groups[2].Value }
        $Result.Bits = $RxMatch.Matches.Groups[3].Value
        $ExeParameters = @('-i')
        $ExeResult = & $ExecutablePath $ExeParameters
        $RxMatch = $ExeResult | Select-String -CaseSensitive -Pattern '^Thread Safety\s*=>\s*(\w+)'
        $Result.ThreadSafe = $RxMatch.Matches.Groups[1].Value -eq 'enabled'
        $RxMatch = $ExeResult | Select-String -CaseSensitive -Pattern '^Compiler\s*=>\s*MSVC([\d]{1,2})'
        $Result.VCVersion = [int] $RxMatch.Matches.Groups[1].Value
        $Result.DownloadUrl = ''
        $Result.ExeFullPath = [System.IO.Path]::GetFullPath($ExecutablePath)
        return $Result
    }
    [int] CompareVersion([PhpVersion] $That) {
        [string] $ThisVersionString = $this.Version
        if ($this.RC -eq '') {
            $ThisVersionString += '.9999';
        } else {
            $ThisVersionString += '.' + $this.RC
        }
        [string] $ThatVersionString = $That.Version
        if ($That.RC -eq '') {
            $ThatVersionString += '.9999';
        } else {
            $ThatVersionString += '.' + $That.RC
        }
        [System.Version] $ThisVersion = [System.Version]$ThisVersionString
        [System.Version] $ThatVersion = [System.Version]$ThatVersionString
        if ($ThisVersion -lt $ThatVersion) {
            return -1
        }
        if ($ThisVersion -gt $ThatVersion) {
            return 1
        }
        if ($this.Bits -lt $That.Bits) {
            return -1
        }
        if ($this.Bits -gt $That.Bits) {
            return 1
        }
        if ($this.ThreadSafe -and -Not $That.ThreadSafe) {
            return -1
        }
        if ($That.ThreadSafe -and -Not $this.ThreadSafe) {
            return 1
        }
        if ($this.Bits -gt $That.Bits) {
            return 1
        }
        return 0
    }
    [bool] IsCompatibleWith([PhpVersion] $That) {
        if ($this.Bits -ne $That.Bits -or $this.ThreadSafe -ne $That.ThreadSafe) {
            return $false
        }
        [System.Version] $ThisVersion = [System.Version]$this.Version
        [System.Version] $ThatVersion = [System.Version]$That.Version
        if ($ThisVersion.Major -ne $ThatVersion.Major -or $ThisVersion.Minor -ne $ThatVersion.Minor) {
            return $false
        }
        return $true
    }
}

function SortPhpVersionList([PhpVersion[]] $List) {
    [int] $MaxIndex = $List.Length - 1
    [int] $MaxIndexM1 = $MaxIndex - 1
    for ([int] $I = 0; $I -lt $MaxIndexM1; $I++) {
        for ([int] $J = $I + 1; $J -lt $MaxIndex; $J++) {
            if ($List[$I].CompareVersion($List[$J]) -gt 0) {
                [PhpVersion] $Temp = $List[$I]
                $List[$I] = $List[$J]
                $List[$J] = $Temp
            }
        }
    }
}

class PhpDownloads {
    hidden static [PhpVersion[]] $QA
    hidden static [PhpVersion[]] $Releases
    hidden static [PhpVersion[]] $Archives
    hidden static [PhpVersion[]] ParseUrl ([string] $PageUrl, [PhpReleaseState] $ReleaseState) {
        [PhpVersion[]] $Result = @()
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $WebResponse = Invoke-WebRequest -UseBasicParsing -Uri $PageUrl
        foreach ($Link in $WebResponse.Links | Where-Object -Property 'Href' -Match ('/' + $Script:RX_ZIPARCHIVE + '$')) {
            $Result += [PhpVersion]::FromUrl($PageUrl, $Link.Href, $ReleaseState)
        }
        #SortPhpVersionList $Result
        return $Result
    }
    static [PhpVersion[]] GetQA () {
        if ([PhpDownloads]::QA -eq $null) {
            [PhpDownloads]::QA = [PhpDownloads]::ParseUrl($Script:URL_QA, [PhpReleaseState]::QA)
        }
       return [PhpDownloads]::QA
    }
    static [PhpVersion[]] GetReleases () {
        if ([PhpDownloads]::Releases -eq $null) {
            [PhpDownloads]::Releases = [PhpDownloads]::ParseUrl($Script:URL_RELEASES, [PhpReleaseState]::Release)
        }
        return [PhpDownloads]::Releases
    }
    static [PhpVersion[]] GetArchives () {
        if ([PhpDownloads]::Archives -eq $null) {
            [PhpDownloads]::Archives = [PhpDownloads]::ParseUrl($Script:URL_ARCHIVES, [PhpReleaseState]::Archive)
        }
        return [PhpDownloads]::Archives
    }
    static [PhpVersion[]] GetList([PhpReleaseState] $ReleaseState) {
        if ($ReleaseState -eq [PhpReleaseState]::QA) {
            return [PhpDownloads]::GetQA()
        }
        if ($ReleaseState -eq [PhpReleaseState]::Release) {
            return [PhpDownloads]::GetReleases()
        }
        if ($ReleaseState -eq [PhpReleaseState]::Archive) {
            return [PhpDownloads]::GetArchives()
        }
        return $null
    }
}

function ParsePhpVersion([string] $Version) {
    $RxMatch = $Version | Select-String -Pattern '^([1-9]\d*)(?:\.(\d+))?(?:\.(\d+))?(RC(\d*))?$'
    if ($RxMatch -eq $null) {
        throw [System.ArgumentException]"Invalid PHP version specified: $Version"
    }
    $SearchReleaseStates=$null
    $RxSearch = '^'
    $RxSearch += [string][int]$RxMatch.Matches.Groups[1].Value + '\.'
    if ($RxMatch.Matches.Groups[2].Value -eq '') {
        $RxSearch += '\d+\.\d+'
    } else {
        $RxSearch += [string][int]$RxMatch.Matches.Groups[2].Value + '\.'
        if ($RxMatch.Matches.Groups[3].Value -eq '') {
            $RxSearch += '\d+'
        } else {
            $RxSearch += [string][int]$RxMatch.Matches.Groups[3].Value
        }
    }
    if ($RxMatch.Matches.Groups[4].Value -ne '') {
        $SearchReleaseStates = @([PhpReleaseState]::QA)
        $RxSearch += 'RC'
        if ($RxMatch.Matches.Groups[5].Value -eq '') {
            $RxSearch += '\d+'
        } else {
            $RxSearch += [string][int]$RxMatch.Matches.Groups[5].Value
        }
    }
    $RxSearch += '$'
    if ($SearchReleaseStates -eq $null) {
        $SearchReleaseStates = @([PhpReleaseState]::Release, [PhpReleaseState]::Archive)
    }
    foreach ($SearchReleaseState in $SearchReleaseStates) {
        $PhpDownloads = [PhpDownloads]::GetList($SearchReleaseState)
        $BestMatch = $null
        foreach ($PhpDownload in $PhpDownloads) {
            $S = $PhpDownload.GetFullVersion()
            if ($S -match $RxSearch) {
                if ($BestMatch -eq $null) {
                    $BestMatch = $PhpDownload
                } elseif ($PhpDownload.CompareVersion($BestMatch) -gt 0) {
                    $BestMatch = $PhpDownload
                }
            }
        }
        if ($BestMatch -ne $null) {
            $Result = @()
            foreach ($PhpDownload in $PhpDownloads) {
                if ($PhpDownload.GetFullVersion() -eq $BestMatch.GetFullVersion()) {
                    $Result += $PhpDownload
                }
            }
            return $Result
        }
    }
    throw [System.ArgumentException]"No PHP version matching $Version (Regular expression used: $RxSearch)"
}

function DownloadAndExtractPHP([PhpVersion] $PhpVersion, [string] $DestinationDirectory)
{
    $LocalTemp = [System.IO.Path]::GetTempFileName()
    try {
        $TempDirectory = [System.IO.Path]::GetDirectoryName($LocalTemp)
        $TempName = [System.IO.Path]::GetFileNameWithoutExtension($LocalTemp)
        for ($I = 0;; $I++) {
            $LocalTempNew = [System.IO.Path]::Combine($TempDirectory, $TempName + '-' + [string] $I + '.zip')
            if (-Not( Test-Path $LocalTempNew)) {
                Rename-Item $LocalTemp $LocalTempNew
                $LocalTemp = $LocalTempNew
                break
            }
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing $PhpVersion.DownloadUrl -OutFile $LocalTemp
        Expand-Archive -LiteralPath $LocalTemp -DestinationPath $DestinationDirectory -Force
    } finally {
        Remove-Item -Path $LocalTemp
    }
}

<#
.Synopsis
Installs PHP.

.Description
Download and installs PHP.

.Parameter Version
Specify the PHP version to be installed.
You can use the following syntaxes:
'7' will install the latest '7' version (for example: 7.2.4)
'7.1' will install the latest '7.1' version (for example: 7.1.16)
'7.1.15' will install the exact '7.1.15' version
'7RC' will install the latest release candidate for PHP 7
'7.1RC' will install the latest release candidate for PHP 7.1
'7.1.17RC' will install the latest release candidate for PHP 7.1.17
'7.1.17RC2' will install the exact release candidate for PHP 7.1.17RC2

.Parameter Bits
The number of bits of the atchitecture (32 or 64)

.Parameter ThreadSafe
A boolean value to indicate if the Thread-Safe version should be installed or not.
You usually install the ThreadSafe version if you plan to use PHP with Apache, or the NonThreadSafe version if you'll use PHP in CGI mode.

.Parameter Path
The path of the directory where PHP will be installed

.Parameter AllowNonEmptyPath
Use this switch to enable installing PHP even if the destination directory already exists and it's not empty.
#>
function Install-Php() {
    Param(
        [Parameter(Mandatory = $true)] [ValidatePattern('^\d+(\.\d+)?(\.\d+)?(RC\d*)?$')] [string] $Version,
        [Parameter(Mandatory = $true)] [ValidateSet(32, 64)] [int] $Bits,
        [Parameter(Mandatory = $true)] [bool] $ThreadSafe,
        [Parameter(Mandatory = $true)] [ValidateLength(1, [int]::MaxValue)] [string] $Path,
        [switch] $AllowNonEmptyPath
    )
    $Path = [System.IO.Path]::GetFullPath($Path)
    if ([System.IO.File]::Exists($Path)) {
        throw "The specified installation path ($Path) points to an existing file"
    }
    if (-Not($AllowNonEmptyPath)) {
        if ([System.IO.Directory]::Exists($Path)) {
            if (Test-Path -Path $([System.IO.Path]::Combine($Path, '*'))) {
                throw "The specified installation path ($Path) exists and it's not empty (use the -AllowNonEmptyPath flag to force the installation)"
            }
        }
    }
    $PhpVersion = $null
    foreach ($V in ParsePhpVersion($Version)) {
        if ($V.Bits -eq $Bits -and $V.ThreadSafe -eq $ThreadSafe) {
            $PhpVersion = $V
            break
        }
    }
    if ($PhpVersion -eq $null) {
        throw "No PHP version matching $Bits and thread-safety"
    }
    Write-Host $('Instaling PHP ' + $PhpVersion.DescribeVersion())
    DownloadAndExtractPHP $PhpVersion $Path
}

<#
.Synopsis
Updates PHP.

.Description
Checks if a new PHP version is available: if so updates an existing PHP installation.

.Parameter Path
The path of the directory where PHP is installed.

#>
function Update-Php() {
    Param(
        [Parameter(Mandatory = $true)] [ValidateLength(1, [int]::MaxValue)] [string] $Path
    )
    $InstalledVersion = $null
    $Path = [System.IO.Path]::GetFullPath($Path)
    if ([System.IO.File]::Exists($Path)) {
        $InstalledVersion = [PhpVersion]::FromExecutable($Path)
    } elseif ([System.IO.Directory]::Exists($Path)) {
        $Path = [System.IO.Path]::Combine($Path, 'php.exe')
        if ([System.IO.File]::Exists($Path)) {
            $InstalledVersion = [PhpVersion]::FromExecutable($Path)
        }
    }
    if ($InstalledVersion -eq $null) {
        throw "The specified path ($Path) does not exist."
    }
    Write-Host $('Found PHP version: ' + $InstalledVersion.DescribeVersion())
    if ($InstalledVersion.RC -eq '') {
        $PossibleReleaseStates = @([PhpReleaseState]::Release, [PhpReleaseState]::Archive)
    } else {
        $PossibleReleaseStates = @([PhpReleaseState]::QA)
    }
    $BestNewVersion = $null
    foreach ($PossibleReleaseState in $PossibleReleaseStates) {
        $AvailableDownloads = [PhpDownloads]::GetList($PossibleReleaseState)
        foreach ($AvailableDownload in $AvailableDownloads) {
            if ($AvailableDownload.IsCompatibleWith($InstalledVersion)) {
                if ($BestNewVersion -eq $null) {
                    $BestNewVersion = $AvailableDownload
                } elseif ($AvailableDownload.CompareVersion($BestNewVersion) -gt 0) {
                    $BestNewVersion = $AvailableDownload
                }
            }
        }
        if ($BestNewVersion -ne $null) {
            break
        }
    }
    if ($BestNewVersion -eq $null -or $BestNewVersion.CompareVersion($InstalledVersion) -le 0) {
        if ($BestNewVersion -eq $null) {
            Write-Host $('No new version available.');
        } else {
            Write-Host $('No new version available (latest version is ' + $BestNewVersion.DescribeVersion() + ')')
        }
        return $false
    }
    Write-Host $('Installing new version: ' + $BestNewVersion.DescribeVersion())
    $DestinationDirectory = [System.IO.Path]::GetDirectoryName($InstalledVersion.ExeFullPath)
    DownloadAndExtractPHP $BestNewVersion $DestinationDirectory
}

<#
.Synopsis
Get the details about installed PHP versions

.Description
Get the details a PHP version installed in a specific location, or in all the PHP installations found in the current environment PATH.

.Parameter Path
Get the details about PHP installed in this location.
If omitted we'll look for PHP installed in the current PATH.
#>
function Get-InstalledPhp() {
    Param(
        [Parameter(Mandatory = $false)] [string] $Path
    )
    if ($Path -ne $null -and $Path -ne '') {
        $Path = [System.IO.Path]::GetFullPath($Path)
        if ([System.IO.File]::Exists($Path)) {
            return [PhpVersion]::FromExecutable($Path)
        }
        if ([System.IO.Directory]::Exists($Path)) {
            $PhpExe = [System.IO.Path]::Combine($Path, 'php.exe')
            if (-not([System.IO.File]::Exists($PhpExe))) {
                throw "$Path does not contain the PHP executable"
            }
            return [PhpVersion]::FromExecutable($PhpExe)
        }
        throw "Unable to find the directory/file $Path"
    }
    foreach ($Path in @($env:path.split(';'))) {
        $PhpExe = [System.IO.Path]::Combine($Path, 'php.exe')
        if ([System.IO.File]::Exists($PhpExe)) {
            $Result += [PhpVersion]::FromExecutable($PhpExe)
        }
    }
    return $Result
}
#>

Export-ModuleMember -Function Install-Php, Update-Php, Get-InstalledPhp