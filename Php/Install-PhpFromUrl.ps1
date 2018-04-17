function Install-PhpFromUrl() {
    <#
    .Synopsis
    Installs PHP, fetching its binary archive from an URL.

    .Parameter Url
    The URL where the binary archive can be downloaded from.

    .Parameter Path
    The path where the archive should be extracted to
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The URL where the binary archive can be downloaded from')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'The path where the archive should be extracted to')]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    Begin {
    }
    Process {
        $temporaryFile = [System.IO.Path]::GetTempFileName()
        try {
            $temporaryDirectory = [System.IO.Path]::GetDirectoryName($temporaryFile)
            $temporaryName = [System.IO.Path]::GetFileNameWithoutExtension($temporaryFile)
            for ($i = 0;; $i++) {
                $newTemporaryFile = [System.IO.Path]::Combine($temporaryDirectory, $temporaryName + '-' + [string] $i + '.zip')
                if (-Not( Test-Path $newTemporaryFile)) {
                    Rename-Item $temporaryFile $newTemporaryFile
                    $temporaryFile = $newTemporaryFile
                    break
                }
            }
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
            Invoke-WebRequest -UseBasicParsing $Url -OutFile $temporaryFile
            Expand-Archive -LiteralPath $temporaryFile -DestinationPath $Path -Force
        } finally {
            Remove-Item -Path $temporaryFile
        }
    }
    End {
    }
}