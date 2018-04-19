Function Set-PhpIniLines
{
    <#
    .Synopsis
    Sets the lines of a php.ini file.

    .Parameter Path
    The path to the php.ini (or to the folder containing it).

    .Parameter Lines
    The new lines to be added to the php.ini.
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the php.ini (or to the folder containing it)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The new lines to be added to the php.ini')]
        [ValidateNotNull()]
        [System.Array]$Lines
    )
    Begin {
    }
    Process {
        If (Test-Path -Path $Path -PathType Container) {
            $Path = [System.IO.Path]::Combine($Path, 'php.ini')
        }
        Set-Content -Path $Path -Value $Lines
    }
    End {
    }
}
