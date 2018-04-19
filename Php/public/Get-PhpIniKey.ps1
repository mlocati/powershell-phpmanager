Function Get-PhpIniKey
{
    <#
    .Synopsis
    Get the value of an entry in the php.ini file.

    .Parameter Path
    The path to a php.ini file, the path to a php.exe file or the folder containing php.exe.

    .Parameter Key
    The key of the php.ini to get.

    .Example
    Get-PhpIniKey 'C:\Dev\PHP\php.ini' 'default_charset'

    .Example
    Get-PhpIniKey 'C:\Dev\PHP' 'default_charset'

    .Example
    Get-PhpIniKey 'C:\Dev\PHP\php.exe' 'default_charset'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to a php.ini file, the path to a php.exe file or the folder containing php.exe')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The key of the php.ini to get')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key
    )
    Begin {
        $result = $null
    }
    Process {
        If ($Path -like '*.exe' -or (Test-Path -Path $Path -PathType Container)) {
            $phpVersion = Get-PhpVersionFromPath -Path $Path
            $iniPath = $phpVersion.IniPath
            If (-Not($iniPath)) {
                Throw "The PHP at $Path does not have a configured php.ini"
            }
        } Else {
            $iniPath = $Path
        }
        If ($Key -match '\bextension\b') {
            Throw 'You can''t use this command to get the extension key'
        }
        $rxSearch = '^\s*' + [Regex]::Escape($Key) + '\s*=\s*(.*?)\s*$'
        ForEach ($line in $(Get-PhpIniLines -Path $iniPath)) {
            $match = $line | Select-String -Pattern $rxSearch
            if ($match) {
                $result = $match.Matches[0].Groups[1].Value
            }
        }
    }
    End {
        $result
    }
}
