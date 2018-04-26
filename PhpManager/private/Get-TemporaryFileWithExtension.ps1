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
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension
    )
    Begin {
        $temporaryFilePath = $null
    }
    Process {
        If ($null -eq $Extension -or $Extension -eq '') {
            $Extension = ''
        } ElseIf ($Extension[0] -ne '.') {
            $Extension = '.' + $Extension
        }
        $originalTemporaryFilePath = [System.IO.Path]::GetTempFileName()
        Try {
            $temporaryDirectoryPath = [System.IO.Path]::GetDirectoryName($originalTemporaryFilePath)
            $temporaryFileName = [System.IO.Path]::GetFileNameWithoutExtension($originalTemporaryFilePath)
            For ($i = 0;; $i++) {
                If ($i -eq 0) {
                    $suffix = ''
                } Else {
                    $suffix = '-' + [string]$i
                }
                $temporaryFilePath = [System.IO.Path]::Combine($temporaryDirectoryPath, $temporaryFileName + $suffix + $Extension)
                If ($temporaryFilePath -eq $originalTemporaryFilePath) {
                    Break
                }
                If (-Not(Test-Path -LiteralPath $temporaryFilePath)) {
                    Rename-Item -LiteralPath $originalTemporaryFilePath -NewName $temporaryFilePath
                    Break
                }
            }
        } Catch {
            Try {
                Remove-Item -LiteralPath $originalTemporaryFilePath
            } Catch {
                Write-Debug 'Failed to remove a temporary file'
            }
        }
    }
    End {
        $temporaryFilePath
    }
}
