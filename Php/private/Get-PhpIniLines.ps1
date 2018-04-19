Function Get-PhpIniLines
{
    <#
    .Synopsis
    Gets the lines contained in a php.ini file.

    .Parameter Path
    The path to the php.ini (or to the folder containing it).

    .Outputs
    System.Array
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the php.ini (or to the folder containing it)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    Begin {
        $lines = @()
    }
    Process {
        If (Test-Path -Path $Path -PathType Container) {
            $Path = [System.IO.Path]::Combine($Path, 'php.ini')
        }
        If (Test-Path -Path $Path -PathType Leaf) {
            $lines = Get-Content -Path $Path
        }
    }
    End {
        $lines
    }
}
