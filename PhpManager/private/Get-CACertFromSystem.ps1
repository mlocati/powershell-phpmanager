function Get-CACertFromSystem
{
    <#
    .Synopsis
    Get the root CA Certificates from the Windows store
    #>
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateSet('LocalMachine', 'CurrentUser')]
        [string] $Source
    )
    begin {
        $result = $null
    }
    process {
        $certsPath = "Cert:\$Source\Root"
        $certs = Get-ChildItem -Path "Cert:\$Source\Root"
        if ($certs.length -eq 0) {
            throw "No certificates found in $certsPath"
        }
        $tempDirectory = New-TempDirectory
        try {
            $stream = New-Object System.IO.MemoryStream
            try {
                $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                try {
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("##`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("## Bundle of CA Root Certificates`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("##`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("## Certificate data from Windows $Source store as of: "))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes([datetime]::Now.ToString('R', [cultureinfo]'en-US')))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("##`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("## Conversion done with PhpManager`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("## https://github.com/mlocati/powershell-phpmanager`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("##`n"))
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("`n"))
                    $counter = 0;
                    foreach ($cert in $certs) {
                        $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("`n"))
                        $name = $cert.FriendlyName
                        if (-not($name)) {
                            $name = $cert.Issuer
                            if (-not($name)) {
                                $name = ''
                            }
                        }
                        $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($name + "`n"))
                        $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes('=' * $name.Length + "`n"))
                        $crtFile = Join-Path -Path $tempDirectory -ChildPath "$counter.crt"
                        Export-Certificate -FilePath $crtFile -Cert $cert -Type CERT | Out-Null
                        $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("-----BEGIN CERTIFICATE-----`n"))
                        $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($crtFile))
                        $base64stringLength = $base64string.Length
                        while ($base64stringLength -gt 64) {
                            $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($base64string.Substring(0, 64)))
                            $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("`n"))
                            $base64string = $base64string.Substring(64)
                            $base64stringLength = $base64stringLength - 64
                        }
                        if ($base64stringLength -gt 0) {
                            $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($base64string))
                            $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("`n"))
                        }
                        $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes("-----END CERTIFICATE-----`n"))
                        $counter++
                    }
                    $result = $stream.ToArray()
                } finally {
                    $streamWriter.Dispose()
                }
            } finally {
                $stream.Dispose()
            }

        } finally {
            try {
                Remove-Item -Path $tempDirectory -Recurse -Force
            } catch {
                Write-Debug 'Failed to remove a temporary directory'
            }
        }
    }
    end {
        $result
    }
}
