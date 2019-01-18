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
        for ($i = 1; ; $i++) {
            try {
                $stream = [System.IO.File]::Open($Path, 'Create', 'Write', 'Read')
                break
            } catch {
                if ($i -ge 3) {
                    throw
                }
            }
        }
        $contents = $Lines | Out-String
        try {
            $writer = New-Object System.IO.StreamWriter($stream)
            try {
                $writer.Write($contents)
            } finally {
                $writer.Dispose()
            }
        } finally {
            $stream.Dispose()
        }
    }
    end {
    }
}
