function Get-PhpIniLine
{
    <#
    .Synopsis
    Gets the lines contained in a php.ini file.

    .Parameter Path
    The path to the php.ini (or to the folder containing it).

    .Outputs
    System.Array
    #>
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The path to the php.ini (or to the folder containing it)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    begin {
        $lines = @()
    }
    process {
        if (Test-Path -Path $Path -PathType Container) {
            $Path = [System.IO.Path]::Combine($Path, 'php.ini')
        }
        if (Test-Path -Path $Path -PathType Leaf) {
            $lines = Get-Content -Path $Path
        }
    }
    end {
        $lines
    }
}
