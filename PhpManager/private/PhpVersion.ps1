Class PhpVersion : System.IComparable
{
    <#
    The version of PHP, without the RC state
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Version
    <#
    The number of the release candidate, if any
    #>
    [Nullable[int]] $RC
    <#
    the version of PHP, possibly including the RC state
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $DisplayVersion
    <#
    A string used to display the details of the version
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $DisplayName
    <#
    A System.Version to be used to compare PHP versions
    #>
    [ValidateNotNull()]
    [System.Version] hidden $ComparableVersion
    <#
    The architecture, x86 or x64
    #>
    [ValidateNotNull()]
    [ValidateSet('x86', 'x64')]
    [string] $Architecture
    <#
    Is this version thread-safe?
    #>
    [ValidateNotNull()]
    [bool] $ThreadSafe
    <#
    The version of the Visual C++ Redistributables required by this PHP version
    #>
    [ValidateNotNull()]
    [int] $VCVersion
    <#
    Initialize the instance.
    Keys for $data:
    - Version: required
    - RC: optional
    - Architecture: required
    - ThreadSafe: required
    - VCVersion: required
    #>
    hidden PhpVersion([Hashtable] $data)
    {
        $this.Version = $data.Version
        If ($data.ContainsKey('RC') -and $data.RC -ne '') {
            $this.RC = [int] $data.RC
        } Else {
            $this.RC = $null
        }
        $dv = $this.Version
        $cv = $this.Version
        If ($null -eq $this.RC) {
            $cv += '.9999'
        } else {
            $dv += 'RC' + $this.RC
            $cv += '.' + $this.RC
        }
        $this.DisplayVersion = $dv
        $this.ComparableVersion = [System.Version] $cv
        $this.Architecture = $data.Architecture
        $this.ThreadSafe = $data.ThreadSafe
        $this.VCVersion = $data.VCVersion
        $dn = 'PHP ' + $this.DisplayVersion + ' ' + $this.Architecture
        if ($this.Architecture -eq $Script:ARCHITECTURE_32BITS) {
            $dn += ' (32-bit)'
        } elseif ($this.Architecture -eq $Script:ARCHITECTURE_64BITS) {
            $dn += ' (64-bit)'
        }
        If ($this.ThreadSafe) {
            $dn += ' Thread-Safe'
        } else {
            $dn += ' Non-Thread-Safe'
        }
        $this.DisplayName = $dn
    }

    [int] CompareTo($that)
    {
        If (-Not($that -is [PhpVersion])) {
            Throw "A PhpVersion instance can be compared only to another PhpVersion instance"
        }
        If ($this.ComparableVersion -lt $that.ComparableVersion) {
            $cmp = -1
        }
        ElseIf ($this.ComparableVersion -gt $that.ComparableVersion) {
            $cmp = 1
        } Else {
            If ($this.Architecture -gt $that.Architecture) {
                $cmp = -1
            } ElseIf ($this.Architecture -lt $that.Architecture) {
                $cmp = -1
            } Else {
                If ($this.ThreadSafe -and -Not $that.ThreadSafe) {
                    $cmp = -1
                } ElseIf ($that.ThreadSafe -and -Not $this.ThreadSafe) {
                    $cmp = 1
                } Else {
                    $cmp = 0
                }
            }
        }
        return $cmp
    }
}

Class PhpVersionDownloadable : PhpVersion
{
    <#
    The state of the release
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $ReleaseState
    <#
    The URL where the PHP version ZIP archive can be downloaded from
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $DownloadUrl
    <#
    Initialize the instance.
    Keys for $data: the ones of PhpVersion plus:
    - ReleaseState: required
    - DownloadUrl: required
    #>
    hidden PhpVersionDownloadable([Hashtable] $data) : base($data)
    {
        $this.ReleaseState = $data.ReleaseState
        $this.DownloadUrl = $data.DownloadUrl
    }
    <#
    .Synopsis
    Creates a new object representing a PHP version from an PHP download URL.
    .Parameter Url
    The PHP download URL (eventually relative to PageUrl).
    .Parameter PageUrl
    The URL of the page where the download link has been retrieved from.
    .Parameter ReleaseState
    One of the $Script:RELEASESTATE_... constants.
    #>
    [PhpVersionDownloadable] static FromUrl([string] $Url, [string] $PageUrl, [string] $ReleaseState)
    {
        $match = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        If ($null -eq $match) {
            Throw "Unrecognized PHP ZIP archive url: $Url"
        }
        $data = @{}
        $data.Version = $match.Matches.Groups[1].Value;
        $data.RC = $match.Matches.Groups[2].Value;
        $data.Architecture = $match.Matches.Groups[5].Value;
        $data.ThreadSafe = $match.Matches.Groups[3].Value -ne '-nts';
        $data.VCVersion = $match.Matches.Groups[4].Value;
        $data.ReleaseState = $ReleaseState;
        If ($null -ne $PageUrl -and $PageUrl -ne '') {
            $data.DownloadUrl = [Uri]::new([Uri]$PageUrl, $Url).AbsoluteUri
        } else {
            $data.DownloadUrl = $Url
        }
        return [PhpVersionDownloadable]::new($data)
    }
}

Class PhpVersionInstalled : PhpVersion
{
    <#
    The folder where PHP is installed (always set)
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $Folder
    <#
    The folder where PHP is installed (always set) - May be different from Folder if Folder is a junction
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] hidden $ActualFolder
    <#
    The full path of php.exe (always set)
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $ExecutablePath
    <#
    The full path of php.ini (always set)
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] hidden $IniPath
    <#
    The default path where the PHP extensions are stored (empty string if not set)
    #>
    [ValidateNotNull()]
    [string] $ExtensionsPath
    <#
    Initialize the instance.
    Keys for $data: the ones of PhpVersion plus:
    - ActualFolder: required
    - ExecutablePath: required
    - IniPath: required
    - ExtensionsPath: optional
    #>
    hidden PhpVersionInstalled([Hashtable] $data) : base($data)
    {
        $this.Folder = (Split-Path -LiteralPath $data.ExecutablePath).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $this.ActualFolder = $data.ActualFolder.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $this.ExecutablePath = $data.ExecutablePath
        $this.IniPath = $data.IniPath
        If ($data.ContainsKey('ExtensionsPath') -and $null -ne $data.ExtensionsPath) {
            $this.ExtensionsPath = $data.ExtensionsPath
        } Else {
            $this.ExtensionsPath = ''
        }
    }
    [PhpVersionInstalled] static FromPath([string] $Path)
    {
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $data = @{}
        $item = Get-Item -LiteralPath $Path
        If ($item -is [System.IO.FileInfo]) {
            if ($item.Extension -ne '.exe') {
                return PhpVersionInstalled::FromPath($item.DirectoryName)
            }
            $directory = $item.Directory
            $data.ExecutablePath = $item.FullName
        } ElseIf($item -is [System.IO.DirectoryInfo]) {
            $directory = $item
            $data.ExecutablePath = Join-Path -Path $item.FullName -ChildPath 'php.exe'
            If (-Not(Test-Path -LiteralPath $data.ExecutablePath -PathType Leaf)) {
                Throw "Unable to find php.exe in $Path"
            }
        } Else {
            Throw "Unrecognized PHP path: $Path"
        }
        $directoryPath = $directory.FullName.TrimEnd($directorySeparator) + $directorySeparator
        $actualDirectoryPath = $null
        If ($directory.Target -and $directory.Target.Count -gt 0 -and $directory.Target[0]) {
            Try {
                $actualDirectoryPath = (Get-Item -LiteralPath $directory.Target[0]).FullName.TrimEnd($directorySeparator) + $directorySeparator
            } Catch {
                Write-Debug $_
            }
        }
        If (-Not($actualDirectoryPath)) {
            $actualDirectoryPath = $directoryPath
        }
        $data.ActualFolder = $actualDirectoryPath.TrimEnd($directorySeparator)
        $executableResult = & $data.ExecutablePath @('-n', '-r', 'echo PHP_VERSION, ''@'', PHP_INT_SIZE * 8;')
        If (-Not($executableResult)) {
            Throw "Failed to execute php.exe: $LASTEXITCODE"
        }
        $match = $executableResult | Select-String -Pattern '^(\d+\.\d+\.\d+)(?:RC(\d+))?@(\d+)$'
        $data.Version = $match.Matches.Groups[1].Value
        $data.RC = $match.Matches.Groups[2].Value
        $data.Architecture = Get-Variable -Scope Script -ValueOnly -Name $('ARCHITECTURE_' + $match.Matches.Groups[3].Value + 'BITS')
        $executableResult = & $data.ExecutablePath @('-i')
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Thread Safety\s*=>\s*(\w+)'
        $data.ThreadSafe = $match.Matches.Groups[1].Value -eq 'enabled'
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Compiler\s*=>\s*MSVC([\d]{1,2})'
        If ($null -eq $match) {
            If ([System.Version]$data.Version -le [System.Version]'5.2.9999') {
                $data.VCVersion = 6
            } Else {
                Throw 'Failed to recognize VCVersion'
            }
        } Else {
            $data.VCVersion = $match.Matches.Groups[1].Value
        }
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Loaded Configuration File\s*=>\s*([\S].*[\S])\s*$'
        $data.IniPath = ''
        If ($match) {
            $data.IniPath = $match.Matches.Groups[1].Value
            If ($data.IniPath -eq '(none)') {
                $data.IniPath = ''
            } Else {
                $data.IniPath = $data.IniPath -replace '/',$directorySeparator
                $data.IniPath = [System.IO.Path]::Combine($actualDirectoryPath, $data.IniPath)
                $data.IniPath = $data.IniPath -replace [regex]::Escape("$directorySeparator.$directorySeparator"),$directorySeparator
            }
        }
        If ($data.IniPath -eq '') {
            $data.IniPath = Join-Path -Path $actualDirectoryPath -ChildPath 'php.ini'
        } ElseIf ($directoryPath -ne $actualDirectoryPath -and $data.IniPath -imatch ('^' + [regex]::Escape($directoryPath) + '.+')) {
            $data.IniPath = $data.IniPath -ireplace ('^' + [regex]::Escape($directoryPath)),$actualDirectoryPath
        }
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*extension_dir\s*=>\s*([\S].*[\S])\s*=>'
        $data.ExtensionsPath = ''
        If ($match) {
            $data.ExtensionsPath = $match.Matches.Groups[1].Value
            If ($data.ExtensionsPath -eq '(none)') {
                $data.ExtensionsPath = ''
            } Else {
                $data.ExtensionsPath = $data.ExtensionsPath -replace '/',$directorySeparator
                $data.ExtensionsPath = [System.IO.Path]::Combine($actualDirectoryPath, $data.ExtensionsPath)
                $data.ExtensionsPath = $data.ExtensionsPath -replace [regex]::Escape("$directorySeparator.$directorySeparator"),$directorySeparator
            }
        }
        return [PhpVersionInstalled]::new($data)
    }
    [PhpVersionInstalled[]] static FromEnvironment()
    {
        $result = @()
        $envPath = $env:Path
        If ($null -ne $envPath -and $envPath -ne '') {
            $donePaths = @{}
            $envPaths = $envPath -split [System.IO.Path]::PathSeparator
            ForEach ($path in $envPaths) {
                If ($path -ne '') {
                    $ep = Join-Path -Path $path -ChildPath 'php.exe'
                    If (Test-Path -Path $ep -PathType Leaf) {
                        $ep = (Get-Item -LiteralPath $ep).FullName
                        $key = $ep.ToLowerInvariant()
                        If (-Not($donePaths.ContainsKey($key))) {
                            $donePaths[$key] = $true
                            $result += [PhpVersionInstalled]::FromPath($ep)
                        }
                    }
                }
            }
       }
       return $result
    }
    [PhpVersionInstalled] static FromEnvironmentOne()
    {
        $found = [PhpVersionInstalled]::FromEnvironment()
        If ($found.Count -eq 0) {
            Throw "No PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        If ($found.Count -gt 1) {
            Throw "Multiple PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        return $found[0]
    }
}
