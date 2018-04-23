function Update-PhpCAInfo() {
    <#
    .Synopsis
    Initializes or updates the certification authority file for a PHP installation.

    .Description
    This command can be used to configure a PHP installation so that it will use an up-to-date list of valid certification authoriries.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter CAPath
    The path of the CA file to be saved. If omitted, it will be saved as <PHP installation folder>\ssl\cacert.pem

    .Parameter CustomCAPath
    If you have a custom CA certificate, you can use this parameter to specify its path: it will be included with the list of the official CA certificates downloaded.

    .Outputs
    bool
    #>
    Param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path of the CA file to be saved. If omitted, it will be saved as <PHP installation folder>\ssl\cacert.pem')]
        [ValidateNotNull()]
        [string] $CAPath = '',
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The path of a file that contains a custom CA certificate to be added to the official CA list')]
        [ValidateNotNull()]
        [string] $CustomCAPath = ''
    )
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = Get-OnePhpVersionFromEnvironment
        } Else {
            $phpVersion = Get-PhpVersionFromPath -Path $Path
        }
        If ($null -eq $CustomCAPath -or $CustomCAPath -eq '') {
            $CustomCAPath = ''
        } ElseIf (-Not(Test-Path -Path $CustomCAPath -PathType Leaf)) {
            Throw "Unable to find your custom CA file $CustomCAPath"
        }
        Write-Output "Downloading CACert checksum file"
        $checksum = [System.Text.Encoding]::ASCII.GetString($(Invoke-WebRequest -Uri $Script:CACERT_CHECKSUM_URL).Content)
        Write-Output "Downloading CACert file"
        $cacertBytes = $(Invoke-WebRequest -Uri $Script:CACERT_PEM_URL).Content
        Write-Output "Checking CACert file"
        $stream = New-Object System.IO.MemoryStream
        Try {
            $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
            Try {
                $streamWriter.Write($cacertBytes)
                $streamWriter.Flush()
                $stream.Position = 0
                $checksum2 = Get-FileHash -InputStream $stream -Algorithm $Script:CACERT_CHECKSUM_ALGORITHM
                }
            Finally {
                $streamWriter.Dispose()
            }
    }
        Finally {
            $stream.Dispose()
        }
        If (-Not($checksum -match ('^' + $checksum2.Hash + '($|\s)'))) {
            Throw "The checksum of the downloaded CA certificates is wrong!"
        }
        If ($CustomCAPath -ne '') {
            Write-Output "Appending custom CA file"
            $headerTitle = 'Custom CA from {0}' -f $CustomCAPath
            $headerTitle = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($headerTitle))
            $header = "`n" + $headerTitle + "`n" + '=' * $headerTitle.Length + "`n"
            $stream = New-Object System.IO.MemoryStream
            Try {
                $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                Try {
                    $streamWriter.Write($cacertBytes)
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($header))
                    $streamWriter.Write([System.IO.File]::ReadAllBytes($CustomCAPath))
                    $streamWriter.Flush()
                    $cacertBytes = $stream.ToArray()
                }
                Finally {
                    $streamWriter.Dispose()
                }
            }
            Finally {
                $stream.Dispose()
            }
        }
        Write-Output "Saving CA file"
        If ($null -eq $CAPath -or $CAPath -eq '') {
            $CAPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($phpVersion.ExecutablePath), 'ssl', 'cacert.pem')
        } Else {
            $CAPath = [System.IO.Path]::GetFullPath($CAPath)
       }
       $caFolder = [System.IO.Path]::GetDirectoryName($CAPath)
       If (-Not(Test-Path -Path $caFolder -PathType Container)) {
           New-Item -Path $caFolder -ItemType Directory | Out-Null
        }
        Set-Content -Path $CAPath -Value $cacertBytes -Encoding Byte
        $iniPath = $phpVersion.IniPath
        If (-Not($iniPath)) {
            $iniPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($phpVersion.ExecutablePath), 'php.ini')
        }
        $iniValue = Get-PhpIniKey -Key 'curl.cainfo' -Path $iniPath
        If ($iniValue -eq $CAPath) {
            Write-Output "curl.cainfo did not require to be updated"
        } Else {
            Set-PhpIniKey -Key 'curl.cainfo' -Value $CAPath -Path $iniPath
            Write-Output "curl.cainfo updated in php.ini"
        }
        $iniValue = Get-PhpIniKey -Key 'openssl.cafile' -Path $iniPath
        If ($iniValue -eq $CAPath) {
            Write-Output "openssl.cafile did not require to be updated"
        } Else {
            Set-PhpIniKey -Key 'openssl.cafile' -Value $CAPath -Path $iniPath
            Write-Output "openssl.cafile updated in php.ini"
        }
    }
    End {
    }
}
