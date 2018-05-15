function Set-PhpIniLine
{
    <#
    .Synopsis
    Sets the lines of a php.ini file.

    .Parameter Path
    The path to the php.ini (or to the folder containing it).

    .Parameter Lines
    The new lines to be added to the php.ini.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNull()]
        [string[]]$Lines
    )
    begin {
    }
    process {
        if (Test-Path -Path $Path -PathType Container) {
            $Path = [System.IO.Path]::Combine($Path, 'php.ini')
        }
        Set-Content -Path $Path -Value $Lines
    }
    end {
    }
}
