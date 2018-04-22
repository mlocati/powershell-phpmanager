function Install-PhpFromUrl() {
    <#
    .Synopsis
    Installs PHP, fetching its binary archive from an URL.

    .Parameter Url
    The URL where the binary archive can be downloaded from.

    .Parameter Path
    The path where the archive should be extracted to.
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The URL where the binary archive can be downloaded from')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'The path where the archive should be extracted to')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    Begin {
    }
    Process {
        $temporaryFile = Get-ZipFromUrl -Url $Url
        Try {
            Write-Debug "Extracting $temporaryFile"
            Expand-Archive -LiteralPath $temporaryFile -DestinationPath $Path -Force
        } Finally {
            Remove-Item -Path $temporaryFile
        }
    }
    End {
    }
}
