function Get-CACertFromCurl {
    <#
    .Synopsis
    Get the root CA Certificates from the cURL website
    #>
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'Skip the checksum check')]
        [ValidateNotNull()]
        [bool] $SkipChecksumCheck = $false
    )
    begin {
        Set-NetSecurityProtocolType
        $result = $null
    }
    process {
        Write-Verbose "Downloading CACert file from $Script:CACERT_PEM_URL"
        $cacertBytes = $(Invoke-WebRequest -UseBasicParsing -Uri $Script:CACERT_PEM_URL).Content
        if (-not($SkipChecksumCheck)) {
            Write-Verbose "Downloading checksum file from $Script:CACERT_CHECKSUM_URL"
            $checksum = [System.Text.Encoding]::ASCII.GetString($(Invoke-WebRequest -UseBasicParsing -Uri $Script:CACERT_CHECKSUM_URL).Content)
            Write-Verbose "Checking CACert file"
            $stream = New-Object System.IO.MemoryStream
            try {
                $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                try {
                    $streamWriter.Write($cacertBytes)
                    $streamWriter.Flush()
                    $stream.Position = 0
                    $checksum2 = Get-FileHash -InputStream $stream -Algorithm $Script:CACERT_CHECKSUM_ALGORITHM
                }
                finally {
                    $streamWriter.Dispose()
                }
            }
            finally {
                $stream.Dispose()
            }
            if (-Not($checksum -match ('^' + $checksum2.Hash + '($|\s)'))) {
                throw "The checksum of the downloaded CA certificates is wrong!"
            }
        }
        $result = $cacertBytes
    }
    end {
        $result
    }
}
