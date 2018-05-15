function Get-TemporaryFileWithExtension() {
    <#
    .Synopsis
    Creates a new empty temporary file with the specified file extension.

    .Parameter Extension
    The extension of the file.

    .Example
    Get-TemporaryFileWithExtension -Extension 'zip'

    .Example
    Get-TemporaryFileWithExtension -Extension '.zip'

    .Outputs
    string
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension
    )
    begin {
        $temporaryFilePath = $null
    }
    process {
        if ($null -eq $Extension -or $Extension -eq '') {
            $Extension = ''
        } elseif ($Extension[0] -ne '.') {
            $Extension = '.' + $Extension
        }
        $originalTemporaryFilePath = [System.IO.Path]::GetTempFileName()
        try {
            $temporaryDirectoryPath = Split-Path -LiteralPath $originalTemporaryFilePath
            $temporaryFileName = [System.IO.Path]::GetFileNameWithoutExtension($originalTemporaryFilePath)
            for ($i = 0;; $i++) {
                if ($i -eq 0) {
                    $suffix = ''
                } else {
                    $suffix = '-' + [string]$i
                }
                $temporaryFilePath = [System.IO.Path]::Combine($temporaryDirectoryPath, $temporaryFileName + $suffix + $Extension)
                if ($temporaryFilePath -eq $originalTemporaryFilePath) {
                    break
                }
                if (-Not(Test-Path -LiteralPath $temporaryFilePath)) {
                    Rename-Item -LiteralPath $originalTemporaryFilePath -NewName $temporaryFilePath
                    break
                }
            }
        } catch {
            try {
                Remove-Item -LiteralPath $originalTemporaryFilePath
            } catch {
                Write-Debug 'Failed to remove a temporary file'
            }
        }
    }
    end {
        $temporaryFilePath
    }
}
