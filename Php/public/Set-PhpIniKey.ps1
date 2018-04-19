Function Set-PhpIniKey
{
    <#
    .Synopsis
    Sets the value of an entry in the php.ini file.

    .Parameter Path
    The path to a php.ini file, the path to a php.exe file or the folder containing php.exe.

    .Parameter Key
    The key of the php.ini to be set.

    .Parameter Value
    The value of the php.ini key to be set.

    .Parameter Delete
    Specify this switch to delete the key in the php.ini.

    .Parameter Comment
    Specify this switch to comment the key in the php.ini.

    .Example
    Set-PhpIniKey 'C:\Dev\PHP\php.ini' 'default_charset' 'UTF-8'

    .Example
    Set-PhpIniKey 'C:\Dev\PHP\php.ini' 'default_charset' -Comment

    Set-PhpIniKey 'C:\Dev\PHP\php.ini' 'default_charset' -Delete
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to a php.ini file, the path to a php.exe file or the folder containing php.exe')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The key of the php.ini to be set')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'The value of the php.ini key to be set')]
        [string]$Value,
        [switch]$Delete,
        [switch]$Comment
    )
    Begin {
        $newLines = @()
    }
    Process {
        If ($Path -like '*.exe' -or (Test-Path -Path $Path -PathType Container)) {
            Write-Host "Ciao2"
            $phpVersion = Get-PhpVersionFromPath -Path $Path
            $iniFile = $phpVersion.IniPath
            If (-Not($iniFile)) {
                Throw "The PHP at $Path does not have a configured php.ini"
            }
        } Else {
            $iniFile = $Path
        }
        If ($Key -match '\bextension\b') {
            Throw 'You can''t use this command to set the extension key'
        }
        If ($Value -eq $null) {
            $Value = ''
        }
        If ($Delete) {
            If ($Comment) {
                Throw 'You can''t specify both the -Delete and -Comment switches'
            }
            If ($Value -ne '') {
                Throw 'If you specify the -Delete switch, you can''t specify -Value parameter'
            }
            $operation = 'DELETE'
        } ElseIf ($Comment) {
            $operation = 'COMMENT'
            If ($Value -ne '') {
                Throw 'If you specify the -Delete switch, you can''t specify -Value parameter'
            }
        } Else {
            $operation = 'SET'
        }
        $rxSearch = '^\s*([;#][\s;#]*)?(' + [Regex]::Escape($Key) + '\s*)=(.*)$'
        $found = $false
        ForEach ($line in $(Get-PhpIniLines -Path $iniPath)) {
            $match = $line | Select-String -Pattern $rxSearch
            if ($match -eq $null) {
                $newLines += $line
            } ElseIf ($found) {
                If ($operation -ne 'DELETE') {
                    If ($match.Matches[0].Groups[1].Length -eq 0) {
                        $newLines += ';' + $line;
                    } else {
                        $newLines += $line
                    }
                }
            } else {
                $found = $true
                If ($operation -eq 'COMMENT') {
                    If ($match.Matches[0].Groups[1].Length -eq 0) {
                        $newLines += ';' + $line;
                    } Else {
                        $newLines += $line;
                    }
                } ElseIf ($operation -eq 'SET') {
                    $newLines += "$Key=$Value"
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
