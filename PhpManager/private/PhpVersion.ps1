class PhpVersion : System.IComparable
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
    [string] $FullVersion
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
    hidden PhpVersion([hashtable] $data)
    {
        $this.Version = $data.Version
        if ($data.ContainsKey('RC') -and $data.RC -ne '') {
            $this.RC = [int] $data.RC
        } else {
            $this.RC = $null
        }
        $dv = $this.Version
        $cv = $this.Version
        if ($null -eq $this.RC) {
            $cv += '.9999'
        } else {
            $dv += 'RC' + $this.RC
            $cv += '.' + $this.RC
        }
        $this.FullVersion = $dv
        $this.ComparableVersion = [System.Version] $cv
        $this.Architecture = $data.Architecture
        $this.ThreadSafe = $data.ThreadSafe
        $this.VCVersion = $data.VCVersion
        $dn = 'PHP ' + $this.FullVersion + ' ' + $this.Architecture
        if ($this.Architecture -eq $Script:ARCHITECTURE_32BITS) {
            $dn += ' (32-bit)'
        } elseif ($this.Architecture -eq $Script:ARCHITECTURE_64BITS) {
            $dn += ' (64-bit)'
        }
        if ($this.ThreadSafe) {
            $dn += ' Thread-Safe'
        } else {
            $dn += ' Non-Thread-Safe'
        }
        $this.DisplayName = $dn
    }

    [int] CompareTo($that)
    {
        if (-Not($that -is [PhpVersion])) {
            throw "A PhpVersion instance can be compared only to another PhpVersion instance"
        }
        if ($this.ComparableVersion -lt $that.ComparableVersion) {
            $cmp = -1
        } elseif ($this.ComparableVersion -gt $that.ComparableVersion) {
            $cmp = 1
        } else {
            if ($this.Architecture -gt $that.Architecture) {
                $cmp = -1
            } elseif ($this.Architecture -lt $that.Architecture) {
                $cmp = -1
            } else {
                if ($this.ThreadSafe -and -Not $that.ThreadSafe) {
                    $cmp = -1
                } elseif ($that.ThreadSafe -and -Not $this.ThreadSafe) {
                    $cmp = 1
                } else {
                    $cmp = 0
                }
            }
        }
        return $cmp
    }
}

class PhpVersionDownloadable : PhpVersion
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
    hidden PhpVersionDownloadable([hashtable] $data) : base($data)
    {
        $this.ReleaseState = $data.ReleaseState
        $this.DownloadUrl = $data.DownloadUrl
    }
}

class PhpVersionInstalled : PhpVersion
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
    hidden PhpVersionInstalled([hashtable] $data) : base($data)
    {
        $this.Folder = (Split-Path -LiteralPath $data.ExecutablePath).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $this.ActualFolder = $data.ActualFolder.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $this.ExecutablePath = $data.ExecutablePath
        $this.IniPath = $data.IniPath
        if ($data.ContainsKey('ExtensionsPath') -and $null -ne $data.ExtensionsPath) {
            $this.ExtensionsPath = $data.ExtensionsPath
        } else {
            $this.ExtensionsPath = ''
        }
    }
    [PhpVersionInstalled] static FromPath([string] $Path)
    {
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $data = @{}
        $item = Get-Item -LiteralPath $Path
        if ($item -is [System.IO.FileInfo]) {
            if ($item.Extension -ne '.exe') {
                return [PhpVersionInstalled]::FromPath($item.DirectoryName)
            }
            $directory = $item.Directory
            $data.ExecutablePath = $item.FullName
        } elseif ($item -is [System.IO.DirectoryInfo]) {
            $directory = $item
            $data.ExecutablePath = Join-Path -Path $item.FullName -ChildPath 'php.exe'
            if (-Not(Test-Path -LiteralPath $data.ExecutablePath -PathType Leaf)) {
                throw "Unable to find php.exe in $Path"
            }
        } else {
            throw "Unrecognized PHP path: $Path"
        }
        $directoryPath = $directory.FullName.TrimEnd($directorySeparator) + $directorySeparator
        $actualDirectoryPath = $null
        if ($directory.Target -and $directory.Target.Count -gt 0 -and $directory.Target[0]) {
            try {
                $actualDirectoryPath = (Get-Item -LiteralPath $directory.Target[0]).FullName.TrimEnd($directorySeparator) + $directorySeparator
            } catch {
                Write-Debug $_
            }
        }
        if (-Not($actualDirectoryPath)) {
            $actualDirectoryPath = $directoryPath
        }
        $data.ActualFolder = $actualDirectoryPath.TrimEnd($directorySeparator)
        $executableResult = & $data.ExecutablePath @('-n', '-r', 'echo PHP_VERSION, ''@'', PHP_INT_SIZE * 8;')
        if (-Not($executableResult)) {
            throw "Failed to execute php.exe: $LASTEXITCODE"
        }
        $match = $executableResult | Select-String -Pattern '^(\d+\.\d+\.\d+)(?:RC(\d+))?@(\d+)$'
        $data.Version = $match.Matches.Groups[1].Value
        $data.RC = $match.Matches.Groups[2].Value
        $data.Architecture = Get-Variable -Scope Script -ValueOnly -Name $('ARCHITECTURE_' + $match.Matches.Groups[3].Value + 'BITS')
        $executableResult = & $data.ExecutablePath @('-i')
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Thread Safety\s*=>\s*(\w+)'
        $data.ThreadSafe = $match.Matches.Groups[1].Value -eq 'enabled'
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Compiler\s*=>\s*MSVC([\d]{1,2})'
        if ($null -eq $match) {
            if ([System.Version]$data.Version -le [System.Version]'5.2.9999') {
                $data.VCVersion = 6
            } else {
                throw 'Failed to recognize VCVersion'
            }
        } else {
            $data.VCVersion = $match.Matches.Groups[1].Value
        }
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Loaded Configuration File\s*=>\s*([\S].*[\S])\s*$'
        $data.IniPath = ''
        if ($match) {
            $data.IniPath = $match.Matches.Groups[1].Value
            if ($data.IniPath -eq '(none)') {
                $data.IniPath = ''
            } else {
                $data.IniPath = $data.IniPath -replace '/',$directorySeparator
                $data.IniPath = [System.IO.Path]::Combine($actualDirectoryPath, $data.IniPath)
                $data.IniPath = $data.IniPath -replace [regex]::Escape("$directorySeparator.$directorySeparator"),$directorySeparator
            }
        }
        if ($data.IniPath -eq '') {
            $data.IniPath = Join-Path -Path $actualDirectoryPath -ChildPath 'php.ini'
        } elseif ($directoryPath -ne $actualDirectoryPath -and $data.IniPath -imatch ('^' + [regex]::Escape($directoryPath) + '.+')) {
            $data.IniPath = $data.IniPath -ireplace ('^' + [regex]::Escape($directoryPath)),$actualDirectoryPath
        }
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*extension_dir\s*=>\s*([\S].*[\S])\s*=>'
        $data.ExtensionsPath = ''
        if ($match) {
            $data.ExtensionsPath = $match.Matches.Groups[1].Value
            if ($data.ExtensionsPath -eq '(none)') {
                $data.ExtensionsPath = ''
            } else {
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
        if ($null -ne $envPath -and $envPath -ne '') {
            $donePaths = @{}
            $envPaths = $envPath -split [System.IO.Path]::PathSeparator
            foreach ($path in $envPaths) {
                if ($path -ne '') {
                    $ep = Join-Path -Path $path -ChildPath 'php.exe'
                    if (Test-Path -Path $ep -PathType Leaf) {
                        $ep = (Get-Item -LiteralPath $ep).FullName
                        $key = $ep.ToLowerInvariant()
                        if (-Not($donePaths.ContainsKey($key))) {
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
        if ($found.Count -eq 0) {
            throw "No PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        if ($found.Count -gt 1) {
            throw "Multiple PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        return $found[0]
    }
}
