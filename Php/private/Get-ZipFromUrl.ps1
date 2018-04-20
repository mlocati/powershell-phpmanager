function Get-ZipFromUrl() {
    <#
    .Synopsis
    Downloads a Zip file.

    .Parameter Url
    The URL where the Zip archive can be downloaded from.

    .Outputs
    string
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url
    )
    Begin {
        $localFile = $null
    }
    Process {
        $ok = $false
        $localFile = [System.IO.Path]::GetTempFileName()
        Try {
            $temporaryDirectory = [System.IO.Path]::GetDirectoryName($localFile)
            $temporaryName = [System.IO.Path]::GetFileNameWithoutExtension($localFile)
            For ($i = 0;; $i++) {
                $newTemporaryFile = [System.IO.Path]::Combine($temporaryDirectory, $temporaryName + '-' + [string] $i + '.zip')
                If (-Not( Test-Path $newTemporaryFile)) {
                    Rename-Item $localFile $newTemporaryFile
                    $localFile = $newTemporaryFile
                    Break
                }
            }
            Try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
            }
            Catch {
            }
            Write-Debug "Downloading from $Url"
            Invoke-WebRequest -UseBasicParsing $Url -OutFile $localFile
            $ok = $true
        } Finally {
            If (-Not($ok)) {
                Try {
                    Remove-Item -Path $localFile
                }
                Catch {
                }
            }
        }
    }
    End {
        $localFile
    }
}
