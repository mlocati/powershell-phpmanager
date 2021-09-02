class PhpVersion : System.IComparable
{
    <#
    The major.minor version of PHP
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $MajorMinorVersion
    <#
    The version of PHP, without the snapshot/alpha/beta/RC state
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Version
    <#
    The version of PHP, possibly including the alpha/beta/RC state
    #>
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [string] $FullVersion
    <#
    The unstability level, if any (snapshot, alpha, beta, RC)
    #>
    [string]
    [ValidateNotNull()]
    $UnstabilityLevel
    <#
    The unstability version, if any
    #>
    [Nullable[int]] $UnstabilityVersion
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
    - UnstabilityLevel: optional
    - UnstabilityVersion: optional
    - Architecture: required
    - ThreadSafe: required
    - VCVersion: required
    #>
    hidden PhpVersion([hashtable] $data)
    {
        if ($data.ContainsKey('UnstabilityLevel') -and $null -ne $data.UnstabilityLevel) {
            $this.UnstabilityLevel = $data.UnstabilityLevel
        } else {
            $this.UnstabilityLevel = ''
        }
        if ($data.ContainsKey('UnstabilityVersion') -and $null -ne $data.UnstabilityVersion -and $data.UnstabilityVersion -ne '') {
            if ($this.UnstabilityLevel -eq '') {
                throw "UnstabilityVersion provided without UnstabilityLevel"
            }
            $this.UnstabilityVersion = [int] $data.UnstabilityVersion
        } elseif ($this.UnstabilityLevel -ne $Script:UNSTABLEPHP_SNAPSHOT)  {
            $this.UnstabilityLevel = $null
        }
        $this.Version = $data.Version
        if ($data.Version -eq 'master') {
            $this.MajorMinorVersion = 'master'
            $this.FullVersion = 'master'
            $this.ComparableVersion = [Version]'99.99'
        } else {
            $dv = $data.Version
            $cv = $data.Version
            switch ($this.UnstabilityLevel) {
                '' {
                    $cv += '.9999999'
                }
                $Script:UNSTABLEPHP_RELEASECANDIDATE_LC {
                    $dv += $Script:UNSTABLEPHP_RELEASECANDIDATE_LC + $this.UnstabilityVersion
                    $cv += '.' + (8000000  + $this.UnstabilityVersion)
                }
                $Script:UNSTABLEPHP_BETA {
                    $dv += $Script:UNSTABLEPHP_BETA + $this.UnstabilityVersion
                    $cv += '.' + (4000000  + $this.UnstabilityVersion)
                }
                $Script:UNSTABLEPHP_ALPHA {
                    $dv += $Script:UNSTABLEPHP_ALPHA + $this.UnstabilityVersion
                    $cv += '.' + (2000000  + $this.UnstabilityVersion)
                }
                $Script:UNSTABLEPHP_SNAPSHOT {
                    $dv += '-dev'
                    $cv += '.' + (1000000  + $this.UnstabilityVersion)
                }
                default {
                    throw 'Unrecognized UnstabilityLevel'
                }
            }
            $cv = [System.Version] $cv
            $this.MajorMinorVersion = '{0}.{1}' -f $cv.Major,$cv.Minor
            $this.FullVersion = $dv
            $this.ComparableVersion = $cv
        }
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
    The API version (eg 20190902 for PHP 7.4.0)
    #>
    [ValidateNotNull()]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $ApiVersion
    <#
    Initialize the instance.
    Keys for $data: the ones of PhpVersion plus:
    - ApiVersion: required
    - ActualFolder: required
    - ExecutablePath: required
    - IniPath: required
    - ExtensionsPath: optional
    #>
    hidden PhpVersionInstalled([hashtable] $data) : base($data)
    {
        $this.ApiVersion = $data.ApiVersion
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
        if ($directory.Target) {
            $target = $null
            if ($directory.Target -is [string]) {
                $target = $directory.Target
            } elseif ($directory.Target.Count -gt 0) {
                $target = $directory.Target[0]
            }
            if ($target) {
                try {
                    $actualDirectoryPath = (Get-Item -LiteralPath $directory.Target[0]).FullName.TrimEnd($directorySeparator) + $directorySeparator
                } catch {
                    Write-Debug $_
                }
            }
        }
        if (-Not($actualDirectoryPath)) {
            $actualDirectoryPath = $directoryPath
        }
        $LASTEXITCODE = 0
        $data.ActualFolder = $actualDirectoryPath.TrimEnd($directorySeparator)
        $executableResult = & $data.ExecutablePath @('-n', '-r', (@'
ob_start();
phpinfo();
$phpinfo = ob_get_contents();
ob_clean();
if (!preg_match('/^PHP Extension\s*=>\s*(\d+)$/m', $phpinfo, $matches)) {
    fwrite(STDERR, 'Failed to find the PHP Extension API');
    exit(1);
}
echo PHP_VERSION, chr(9), PHP_INT_SIZE * 8, chr(9), $matches[1];
'@ -replace "`r`n", ' ' -replace "`n", ' ')
        )

        if ($LASTEXITCODE -ne 0 -or -Not($executableResult)) {
            throw "Failed to execute php.exe: $LASTEXITCODE"
        }
        $match = $executableResult | Select-String -Pattern "(?<version>\d+\.\d+\.\d+)(?<stabilityLevel>([Rr][Cc]\d+)?-dev|(?:$Script:UNSTABLEPHP_RX))?(?<stabilityVersion>\d+)?\t(?<bits>\d+)\t(?<apiVersion>\d+)$"
        if (-not($match)) {
            throw "Unsupported PHP version: $executableResult"
        }
        $groups = $match.Matches[0].Groups
        $data.Version = $groups['version'].Value
        if ($groups['stabilityLevel'].Value -match '-dev$') {
            $data.UnstabilityLevel = $Script:UNSTABLEPHP_SNAPSHOT
        } else {
            $data.UnstabilityLevel = $groups['stabilityLevel'].Value
            $data.UnstabilityVersion = $groups['stabilityVersion'].Value
        }
        $data.Architecture = Get-Variable -Scope Script -ValueOnly -Name $('ARCHITECTURE_' +  $groups['bits'].Value + 'BITS')
        $data.ApiVersion = [int] $groups['apiVersion'].Value
        $executableResult = & $data.ExecutablePath @('-i')
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Thread Safety\s*=>\s*(\w+)'
        $data.ThreadSafe = $match.Matches.Groups[1].Value -eq 'enabled'
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Compiler\s*=>\s*MSVC([\d]{1,2})'
        if ($null -ne $match) {
            $data.VCVersion = $match.Matches.Groups[1].Value
        } elseif ([System.Version]$data.Version -le [System.Version]'5.2.9999') {
            $data.VCVersion = 6
        } else {
            $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Compiler\s*=>\s*Visual C\+\+\s+(\d{4})(?:\s|$)'
            if ($null -eq $match) {
                throw "Failed to recognize VCVersion"
            }
            $vcYear = $match.Matches.Groups[1].Value
            switch ($vcYear) {
                '2017' { $data.VCVersion = 15 }
                '2019' { $data.VCVersion = 16 }
                default { throw "Failed to recognize VCVersion from Visual C++ $vcYear" }
            }
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
        $numFound = $found.Count
        if ($numFound -eq 0) {
            throw "No PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        if ($numFound -eq 1) {
            $resultIndex = 0
        } else {
            $resultIndex = -1
            Write-Host "Multiple PHP installations have been found.`nPlease specify the PHP installation you want:"
            while($resultIndex -eq -1) {
                for ($index = 0; $index -lt $numFound; $index++) {
                    Write-Host "$($index + 1). $($found[$index].Folder)`n  $($found[$index].DisplayName)"
                }
                $choice = Read-Host "x. Cancel`n`nYour choice (1... $numFound, or x)? "
                if ($choice -eq 'x') {
                    throw 'Operation aborted.'
                }
                try {
                    $resultIndex = [int]$choice - 1
                    if ($resultIndex -lt 0 -or $resultIndex -ge $numFound) {
                        $resultIndex = -1
                    }
                } catch {
                    $resultIndex = -1
                }
                if ($resultIndex -eq -1) {
                    Write-Host "`nPlease enter a number between 0 and $numFound, or 'x' to abort.`n"
                }
            }
        }
        return $found[$resultIndex]
    }
}
