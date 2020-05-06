function Install-Php() {
    <#
    .Synopsis
    Installs PHP.

    .Description
    Download and installs a version of PHP.

    .Parameter Version
    Specify the PHP version to be installed.
    You can use the following syntaxes:
    - '7' will install the latest '7' version (for example: 7.2.4)
    - '7.1' will install the latest '7.1' version (for example: 7.1.16)
    - '7.1.15' will install the exact '7.1.15' version
    - '7RC' will install the latest release candidate for PHP 7
    - '7.1RC' will install the latest release candidate for PHP 7.1
    - '7.1.17RC' will install the latest release candidate for PHP 7.1.17
    - '7.1.17RC2' will install the exact release candidate for PHP 7.1.17RC2
    - '7.1snapshot' will install the exact release candidate for PHP 7.1.17RC2
    - 'master' will install the very latest master snapshot

    .Parameter Architecture
    The architecture of the PHP to be installed (x86 for 32-bit, x64 for 64-bit).

    .Parameter ThreadSafe
    A boolean value to indicate if the Thread-Safe version should be installed or not.
    You usually install the ThreadSafe version if you plan to use PHP with Apache, or the NonThreadSafe version if you'll use PHP in CGI mode.

    .Parameter Path
    The path of the directory where PHP will be installed.

    .Parameter TimeZone
    The PHP time zone to configure if php.ini does not exist (if not specified: we'll use UTC).

    .Parameter AddToPath
    Specify if you want to add the PHP installation folder to the user ('User') or system ('System') PATH environment variable.
    Please remark that using 'System' usually requires administrative rights.

    .Parameter InitialPhpIni
    Specify to initialize the initial php.ini with the bundled php.ini-production ('Production') or with the bundled php.ini-development ('Development').
    If you don't specify this value, an almost empty php.ini will be created.

    .Parameter InstallVC
    Specify this switch to try to install automatically the required Visual C++ Redistributables (requires the VcRedist PowerShell package, and to run the process as an elevated user).

    .Parameter Force
    Use this switch to enable installing PHP even if the destination directory already exists and it's not empty.
    #>
    [OutputType()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ThreadSafe', Justification = 'False positive as rule does not know that Where-Object operates within the same scope')] # See https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The PHP version to be installed')]
        [ValidatePattern('^(master|(\d+\.\d+snapshot)|(\d+(\.\d+)?(\.\d+)?((alpha|beta|RC)\d*)?))$')]
        [string] $Version,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'Architecture of the PHP to be installed (x86 for 32-bit, x64 for 64-bit)')]
        [ValidateSet('x86', 'x64')]
        [string] $Architecture,
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = 'Install a Thread-Safe version?')]
        [bool] $ThreadSafe,
        [Parameter(Mandatory = $true, Position = 3, HelpMessage = 'The path of the directory where PHP will be installed')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = 'The PHP time zone to configure if php.ini does not exist (if not specified: we''ll use UTC)')]
        [string] $TimeZone,
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = 'Specify if you want to add the PHP installation folder to the user (''User'') or system (''System'') PATH environment variable')]
        [ValidateSet('User', 'System')]
        [string] $AddToPath,
        [Parameter(Mandatory = $false, Position = 6, HelpMessage = 'Specify to initialize the initial php.ini with the bundled php.ini-production (''Production'') or with the bundled php.ini-development (''Development''); if you don''t specify this value, an almost empty php.ini will be created')]
        [ValidateSet('Production', 'Development')]
        [string] $InitialPhpIni,
        [switch] $InstallVC,
        [switch] $Force
    )
    begin {
    }
    process {
        if ($Architecture -eq 'x64' -and [System.IntPtr]::Size -lt 8) {
            throw 'The current operating system is not 64 bits: you can only install with the x86 architecture'
        }
        $Path = [System.IO.Path]::GetFullPath($Path)
        # Check existency
        if (Test-Path -Path $Path -PathType Leaf) {
            throw "The specified installation path ($Path) points to an existing file"
        }
        if (-Not($Force)) {
            if (Test-Path -Path $([System.IO.Path]::Combine($Path, '*'))) {
                throw "The specified installation path ($Path) exists and it's not empty (use the -Force flag to force the installation)"
            }
        }
        # Check $Version format
        if ($Version -eq 'master') {
            $searchReleaseStates = @($Script:RELEASESTATE_SNAPSHOT)
            $rxSearchVersion = '^master$'
        } else {
            $match = $Version | Select-String -Pattern "^(\d+\.\d+)snapshot$"
            if ($null -ne $match) {
                $searchReleaseStates = @($Script:RELEASESTATE_SNAPSHOT)
                $rxSearchVersion = "^$($match.Matches[0].Groups[1].Value -replace '\.', '\.')-dev$"
            } else {
                $match = $Version | Select-String -Pattern "^([1-9]\d*)(?:\.(\d+))?(?:\.(\d+))?(?:($Script:UNSTABLEPHP_RX)(\d*))?$"
                if ($null -eq $match) {
                    throw "The specified PHP version ($Version) is malformed"
                }
                # Build the regular expression to match the version, and determine the list of release states
                $rxSearchVersion = '^'
                $rxSearchVersion += $match.Matches.Groups[1].Value + '\.'
                if ($match.Matches.Groups[2].Value -eq '') {
                    $rxSearchVersion += '\d+\.\d+'
                } else {
                    $rxSearchVersion += [string][int]$match.Matches.Groups[2].Value + '\.'
                    if ($match.Matches.Groups[3].Value -eq '') {
                        $rxSearchVersion += '\d+'
                    } else {
                        $rxSearchVersion += [string][int]$match.Matches.Groups[3].Value
                    }
                }
                if ($match.Matches.Groups[4].Value -eq '') {
                    $searchReleaseStates = @($Script:RELEASESTATE_RELEASE, $Script:RELEASESTATE_ARCHIVE)
                } else {
                    $rxSearchVersion += $match.Matches.Groups[4].Value
                    if ($match.Matches.Groups[5].Value -eq '') {
                        $rxSearchVersion += '\d+'
                    } else {
                        $rxSearchVersion += [string][int]$match.Matches.Groups[5].Value
                    }
                    $searchReleaseStates = @($Script:RELEASESTATE_QA)
                }
                $rxSearchVersion += '$'
            }
        }
        # Filter the list of available PHP versions, and get the latest one
        $versionToInstall = $null
        foreach ($searchReleaseState in $searchReleaseStates) {
            $compatibleVersions = Get-PhpAvailableVersion -State $searchReleaseState | Where-Object { $_.FullVersion -match $rxSearchVersion -and $_.Architecture -eq $Architecture -and $_.ThreadSafe -eq $ThreadSafe }
            foreach ($compatibleVersion in $compatibleVersions) {
                if ($null -eq $versionToInstall) {
                    $versionToInstall = $compatibleVersion
                } elseif ($compatibleVersions -gt $versionToInstall) {
                    $versionToInstall = $compatibleVersion
                }
            }
            if ($null -ne $versionToInstall) {
                break
            }
        }
        if ($null -eq $versionToInstall) {
            throw 'No PHP version matches the specified criterias'
        }
        # Install the found PHP version
        Write-Verbose $('Installing PHP ' + $versionToInstall.DisplayName)
        Install-PhpFromUrl -Url $versionToInstall.DownloadUrl -Path $Path -PhpVersion $versionToInstall -InstallVCRedist $InstallVC
        # Initialize the php.ini
        $iniPath = [System.IO.Path]::Combine($Path, 'php.ini');
        if ($null -ne $InitialPhpIni -and $InitialPhpIni -ne '') {
            $sourceIniPath = [System.IO.Path]::Combine($Path, 'php.ini-' + $InitialPhpIni.ToLowerInvariant());
            Copy-Item -Path $sourceIniPath -Destination $iniPath -Force
            $initializePhpIni = $true
        } else {
            $initializePhpIni = -Not(Test-Path -Path $iniPath -PathType Leaf)
        }
        if ($initializePhpIni) {
            if ($null -eq $TimeZone -or $TimeZone -eq '') {
                $TimeZone = 'UTC'
            }
            Set-PhpIniKey -Key 'date.timezone' -Value $TimeZone -Path $iniPath
            Set-PhpIniKey -Key 'default_charset' -Value 'UTF-8' -Path $iniPath
            Set-PhpIniKey -Key 'extension_dir' -Value $([System.IO.Path]::Combine($Path, 'ext')) -Path $iniPath
        }
        if ($null -ne $AddToPath -and $AddToPath -ne '') {
            Edit-FolderInPath -Operation Add -Path $Path -Persist $AddToPath -CurrentProcess
        }
    }
    end {
    }
}
