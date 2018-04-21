Function Set-PhpIniKey
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
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The key of the php.ini to set')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'The value of the php.ini key to set')]
        [string]$Value,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'The path to a php.ini file, the path to a php.exe file or the folder containing php.exe; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [switch]$Delete,
        [switch]$Comment,
        [switch]$Uncomment
    )
    Begin {
        $newLines = @()
    }
    Process {
        $phpVersion = $null
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = Get-OnePhpVersionFromEnvironment
        } ElseIf ($Path -like '*.exe' -or (Test-Path -Path $Path -PathType Container)) {
            $phpVersion = Get-PhpVersionFromPath -Path $Path
        }
        If ($null -ne $phpVersion) {
            $iniPath = $phpVersion.IniPath
            If (-Not($iniPath)) {
                Throw "The PHP at $Path does not have a configured php.ini"
            }
        } Else {
            $iniPath = $Path
        }
        If ($Key -match '\bextension\b') {
            Throw 'You can''t use this command to set the extension key'
        }
        If ($null -eq $Value) {
            $Value = ''
        }
        $operation = 'SET'
        $numSwitches = 0
        If ($Delete) {
            If ($Value -ne '') {
                Throw 'If you specify the -Delete switch, you can''t specify -Value parameter'
            }
            $operation = 'DELETE'
            $numSwitches += 1
        }
        If ($Comment) {
            If ($Value -ne '') {
                Throw 'If you specify the -Comment switch, you can''t specify -Value parameter'
            }
            $operation = 'COMMENT'
            $numSwitches += 1
        }
        If ($Uncomment) {
            If ($Value -ne '') {
                Throw 'If you specify the -Uncomment switch, you can''t specify -Value parameter'
            }
            $operation = 'UNCOMMENT'
            $numSwitches += 1
        }
        If ($numSwitches -gt 1) {
            Throw 'You can specify only one of the -Delete, -Comment, -Uncomment switches'
        }
        $rxSearch = '^(\s*)([;#][\s;#]*)?(' + [Regex]::Escape($Key) + '\s*=.*)$'
        $found = $false
        ForEach ($line in $(Get-PhpIniLines -Path $iniPath)) {
            $match = $line | Select-String -Pattern $rxSearch
            if ($null -eq $match) {
                $newLines += $line
            } ElseIf ($found) {
                If ($operation -ne 'DELETE') {
                    If ($match.Matches[0].Groups[2].Value -eq '') {
                        $newLines += ';' + $line;
                    } else {
                        $newLines += $line
                    }
                }
            } else {
                $found = $true
                If ($operation -eq 'COMMENT') {
                    If ($match.Matches[0].Groups[2].Value -eq '') {
                        $newLines += ';' + $line;
                    } Else {
                        $newLines += $line;
                    }
                } ElseIf ($operation -eq 'UNCOMMENT') {
                    If ($match.Matches[0].Groups[2].Value -ne '') {
                        $newLines += $match.Matches[0].Groups[1].Value + $match.Matches[0].Groups[3].Value;
                    } Else {
                        $newLines += $line;
                    }
                } ElseIf ($operation -eq 'SET') {
                    $newLines += $match.Matches[0].Groups[1].Value + "$Key=$Value"
                }
            }
        }
        if ($operation -eq 'SET' -and -Not $found) {
            $newLines += "$Key=$Value"
        }
    }
    End {
        Set-PhpIniLines -Path $iniPath -Lines $newLines
    }
}
