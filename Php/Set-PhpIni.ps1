Function Set-PhpIni
{
    <#
    .Synopsis
    Sets the value of an entry in the php.ini file

    .Parameter Path
    The path to the php.ini (or to the folder containing it)

    .Parameter Key
    The key of the php.ini to be set

    .Parameter Value
    The value of the php.ini key to be set

    .Example
    Set-PhpIni 'C:\Dev\PHP\php.ini' 'default_charset' 'UTF-8'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the php.ini (or to the folder containing it)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The key of the php.ini to be set')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'The value of the php.ini key to be set')]
        [string]$Value
    )
    Begin {
        $newLines = @()
    }
    Process {
        $rxSearch = '^(\s*[;#]+(?:[\s;#]*))?\s*(' + [Regex]::Escape($Key) + '\s*)=(.*)$'
        $found = $false
        ForEach ($line in $(Get-PhpIniLines -Path $Path)) {
            $rxMatch = $line | Select-String -Pattern $rxSearch
            if ($rxMatch -eq $null) {
                $newLines += $line
            } ElseIf ($found) {
                If ($rxMatch.Matches[0].Groups[1].Length -ne 0) {
                    $newLines += ';' + $lines[$lineIndex];
                } else {
                    $newLines += $line
                }
            } else {
                $found = $true
                $newLines += "$Key=$Value"
            }
        }
        if (-Not $found) {
            $newLines += "$Key=$Value"
        }
    }
    End {
        Set-PhpIniLines -Path $Path -Lines $newLines
    }
}
