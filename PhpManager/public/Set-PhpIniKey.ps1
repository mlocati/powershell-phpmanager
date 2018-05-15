function Set-PhpIniKey
{
    <#
    .Synopsis
    Sets the value of an entry in the php.ini file.

    .Parameter Key
    The key of the php.ini to set.

    .Parameter Value
    The value of the php.ini key to set.

    .Parameter Path
    The path to a php.ini file, the path to a php.exe file or the folder containing php.exe.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter Delete
    Specify this switch to delete the key in the php.ini.

    .Parameter Comment
    Specify this switch to comment the key in the php.ini.

    .Parameter Uncomment
    Specify this switch to uncomment the key in the php.ini.

    .Example
    Set-PhpIniKey 'default_charset' 'UTF-8' 'C:\Dev\PHP\php.ini'

    .Example
    Set-PhpIniKey 'default_charset' 'UTF-8' 'C:\Dev\PHP\php.exe'

    .Example
    Set-PhpIniKey 'default_charset' 'UTF-8' 'C:\Dev\PHP'

    .Example
    Set-PhpIniKey 'default_charset' 'UTF-8'

    .Example
    Set-PhpIniKey 'default_charset' -Delete

    .Example
    Set-PhpIniKey 'default_charset' -Comment

    .Example
    Set-PhpIniKey 'default_charset' -Uncomment
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The key of the php.ini to set')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The value of the php.ini key to set')]
        [string]$Value,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The path to a php.ini file, the path to a php.exe file or the folder containing php.exe; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [switch]$Delete,
        [switch]$Comment,
        [switch]$Uncomment
    )
    begin {
        $newLines = @()
    }
    process {
        $phpVersion = $null
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } elseif ($Path -like '*.exe' -or (Test-Path -Path $Path -PathType Container)) {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        if ($null -ne $phpVersion) {
            $iniPath = $phpVersion.IniPath
        } else {
            $iniPath = $Path
        }
        if ($Key -match '^\s*(zend_)?extension\s*$') {
            throw 'You can''t use this command to set the extensions'
        }
        if ($null -eq $Value) {
            $Value = ''
        }
        $operation = 'SET'
        $numSwitches = 0
        if ($Delete) {
            if ($Value -ne '') {
                throw 'If you specify the -Delete switch, you can''t specify -Value parameter'
            }
            $operation = 'DELETE'
            $numSwitches += 1
        }
        if ($Comment) {
            if ($Value -ne '') {
                throw 'If you specify the -Comment switch, you can''t specify -Value parameter'
            }
            $operation = 'COMMENT'
            $numSwitches += 1
        }
        if ($Uncomment) {
            if ($Value -ne '') {
                throw 'If you specify the -Uncomment switch, you can''t specify -Value parameter'
            }
            $operation = 'UNCOMMENT'
            $numSwitches += 1
        }
        if ($numSwitches -gt 1) {
            throw 'You can specify only one of the -Delete, -Comment, -Uncomment switches'
        }
        $rxSearch = '^(\s*)([;#][\s;#]*)?(' + [Regex]::Escape($Key) + '\s*=.*)$'
        $found = $false
        foreach ($line in $(Get-PhpIniLine -Path $iniPath)) {
            $match = $line | Select-String -Pattern $rxSearch
            if ($null -eq $match) {
                $newLines += $line
            } elseif ($found) {
                if ($operation -ne 'DELETE') {
                    if ($match.Matches[0].Groups[2].Value -eq '') {
                        $newLines += ';' + $line;
                    } else {
                        $newLines += $line
                    }
                }
            } else {
                $found = $true
                if ($operation -eq 'COMMENT') {
                    if ($match.Matches[0].Groups[2].Value -eq '') {
                        $newLines += ';' + $line;
                    } else {
                        $newLines += $line;
                    }
                } elseif ($operation -eq 'UNCOMMENT') {
                    if ($match.Matches[0].Groups[2].Value -ne '') {
                        $newLines += $match.Matches[0].Groups[1].Value + $match.Matches[0].Groups[3].Value;
                    } else {
                        $newLines += $line;
                    }
                } elseif ($operation -eq 'SET') {
                    $newLines += $match.Matches[0].Groups[1].Value + "$Key=$Value"
                }
            }
        }
        if ($operation -eq 'SET' -and -Not $found) {
            $newLines += "$Key=$Value"
        }
    }
    end {
        Set-PhpIniLine -Path $iniPath -Lines $newLines
    }
}
