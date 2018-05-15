function Expand-ArchiveWith7Zip
{
    <#
    .Synopsis
    Extracts a .zip archive with 7-zip (more than one order of magnitude faster than Expand-Archive).

    .Parameter ArchivePath
    The path of the archive to be extracted.

    .Parameter DestinationPath
    The path where the archive will be extracted to.

    .Parameter Overwrite
    Specify this flag to overwrite existing files.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$ArchivePath,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$DestinationPath,
        [switch]$Overwrite
    )
    begin {
    }
    process {
        $createdHere = $false
        If (-Not(Test-Path -LiteralPath $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath | Out-Null
            $createdHere = $true
        }
        if ([System.IntPtr]::Size -lt 8) {
            $sevenZipArchitecture = 'x86'
        } else {
            $sevenZipArchitecture = 'x64'
        }
        $sevenZipArguments = @()
        $sevenZipArguments += 'x' # extract with full paths
        $sevenZipArguments += '-bso1' # standard output messages -> stdout
        $sevenZipArguments += '-bse1' # error messages -> stdout
        $sevenZipArguments += '-bsp0' # progress information -> disabled
        $sevenZipArguments += '-bb0' # disable log
        $sevenZipArguments += '-bd' # disable progress indicator
        $sevenZipArguments += '-o' + $DestinationPath # set output directory
        $sevenZipArguments += '-y' # assume Yes on all queries
        if ($Overwrite) {
            $sevenZipArguments += '-aoa' # overwrite all existing files without prompt.
        } else {
            $sevenZipArguments += '-aos' # skip extracting of existing files.
        }
        $sevenZipArguments += $ArchivePath
        $sevenZipPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', "7za-$sevenZipArchitecture.exe")
        $sevenZipResult = & $sevenZipPath $sevenZipArguments
        if ($LASTEXITCODE -ne 0) {
            if ($createdHere) {
                try {
                    Remove-Item -LiteralPath $DestinationPath -Recurse
                } catch {
                    Write-Debug 'Failed to remove extraction directory'
                }
            }
            throw "Error extracting from archive: $sevenZipResult"
        }
    }
    end {
    }
}
