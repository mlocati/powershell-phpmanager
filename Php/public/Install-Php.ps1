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

    .Parameter Force
    Use this switch to enable installing PHP even if the destination directory already exists and it's not empty.
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The PHP version to be installed')]
        [ValidatePattern('^\d+(\.\d+)?(\.\d+)?(RC\d*)?$')]
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
        [switch] $Force
    )
    Begin {
    }
    Process {
        $Path = [System.IO.Path]::GetFullPath($Path)
        # Check existency
        If (Test-Path -Path $Path -PathType Leaf) {
            Throw "The specified installation path ($Path) points to an existing file"
        }
        if (-Not($Force)) {
            if (Test-Path -Path $([System.IO.Path]::Combine($Path, '*'))) {
                Throw "The specified installation path ($Path) exists and it's not empty (use the -Force flag to force the installation)"
            }
        }
        # Check $Version format
        $match = $Version | Select-String -Pattern '^([1-9]\d*)(?:\.(\d+))?(?:\.(\d+))?(RC(\d*))?$'
        If ($null -eq $match) {
            Throw "The specified PHP version ($Version) is malformed"
        }
        # Build the regular expression to match the version, and determine the list of release states
        $rxSearchVersion = '^'
        $rxSearchVersion += $match.Matches.Groups[1].Value + '\.'
        If ($match.Matches.Groups[2].Value -eq '') {
            $rxSearchVersion += '\d+\.\d+'
        } Else {
            $rxSearchVersion += [string][int]$match.Matches.Groups[2].Value + '\.'
            If ($match.Matches.Groups[3].Value -eq '') {
                $rxSearchVersion += '\d+'
            } Else {
                $rxSearchVersion += [string][int]$match.Matches.Groups[3].Value
            }
        }
        If ($match.Matches.Groups[4].Value -eq '') {
            $searchReleaseStates = @($Script:RELEASESTATE_RELEASE, $Script:RELEASESTATE_ARCHIVE)
        } Else {
            $rxSearchVersion += 'RC'
            If ($match.Matches.Groups[5].Value -eq '') {
                $rxSearchVersion += '\d+'
            } Else {
                $rxSearchVersion += [string][int]$match.Matches.Groups[5].Value
            }
            $searchReleaseStates = @($Script:RELEASESTATE_QA)
        }
        $rxSearchVersion += '$'
        # Filter the list of available PHP versions, and get the latest one
        $versionToInstall = $null
        ForEach ($searchReleaseState in $searchReleaseStates) {
            $compatibleVersions = Get-PhpAvailableVersions -State $searchReleaseState | Where-Object {$_.FullVersion -match $rxSearchVersion} | Where-Object {$_.Architecture -eq $Architecture} | Where-Object {$_.ThreadSafe -eq $ThreadSafe}
            ForEach ($compatibleVersion in $compatibleVersions) {
                If ($null -eq $versionToInstall) {
                    $versionToInstall = $compatibleVersion
                } ElseIf ($(Compare-PhpVersions -A $compatibleVersion -B $versionToInstall) -gt 0) {
                    $versionToInstall = $compatibleVersion
                }
            }
            If ($null -ne $versionToInstall) {
                break
            }
        }
        if ($null -eq $versionToInstall) {
            Throw 'No PHP version matches the specified criterias'
        }
        # Install the found PHP version
        
        Write-Output $('Installing PHP ' + $versionToInstall.DisplayName)
        Install-PhpFromUrl -Url $versionToInstall.DownloadUrl -Path $Path
        # Initialize the php.ini
        $IniPath = [System.IO.Path]::Combine($Path, 'php.ini');
        If (-Not(Test-Path -Path $IniPath -PathType Leaf)) {
            if ($null -eq $TimeZone -or $TimeZone -eq '') {
                $TimeZone = 'UTC'
            }
            Set-PhpIniKey -Key 'date.timezone' -Value $TimeZone -Path $IniPath
            Set-PhpIniKey -Key 'default_charset' -Value 'UTF-8' -Path $IniPath
            Set-PhpIniKey -Key 'extension_dir' -Value $([System.IO.Path]::Combine($Path, 'ext')) -Path $IniPath
        }
        If ($null -ne $AddToPath -and $AddToPath -ne '') {
            If ([System.Environment]::GetEnvironmentVariable[0].OverloadDefinitions.Count -lt 2) {
                Write-Warning "The current PowerShell version does not support saving environment variables to ${AddToPath}: we'll set the Path only for the current process"
                Add-PhpFolderToPath -Path $Path -CurrentProcess
            } Else {
                Add-PhpFolderToPath -Path $Path -Persist $AddToPath -CurrentProcess
            }
        }
    }
    End {
    }
}
