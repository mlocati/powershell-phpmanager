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
    [OutputType()]
    param (
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
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        if ($null -eq $CustomCAPath -or $CustomCAPath -eq '') {
            $CustomCAPath = ''
        } elseif (-Not(Test-Path -Path $CustomCAPath -PathType Leaf)) {
            throw "Unable to find your custom CA file $CustomCAPath"
        }
        Write-Verbose "Downloading CACert checksum file"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
        } catch {
            Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
        }
        $checksum = [System.Text.Encoding]::ASCII.GetString($(Invoke-WebRequest -Uri $Script:CACERT_CHECKSUM_URL).Content)
        Write-Verbose "Downloading CACert file"
        $cacertBytes = $(Invoke-WebRequest -Uri $Script:CACERT_PEM_URL).Content
        Write-Verbose "Checking CACert file"
        $stream = New-Object System.IO.MemoryStream
        try {
            $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
            try {
                $streamWriter.Write($cacertBytes)
                $streamWriter.Flush()
                $stream.Position = 0
                $checksum2 = Get-FileHash -InputStream $stream -Algorithm $Script:CACERT_CHECKSUM_ALGORITHM
            } finally {
                $streamWriter.Dispose()
            }
        } finally {
            $stream.Dispose()
        }
        if (-Not($checksum -match ('^' + $checksum2.Hash + '($|\s)'))) {
            throw "The checksum of the downloaded CA certificates is wrong!"
        }
        if ($CustomCAPath -ne '') {
            Write-Verbose "Appending custom CA file"
            $headerTitle = 'Custom CA from {0}' -f $CustomCAPath
            $headerTitle = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($headerTitle))
            $header = "`n" + $headerTitle + "`n" + '=' * $headerTitle.Length + "`n"
            $stream = New-Object System.IO.MemoryStream
            try {
                $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                try {
                    $streamWriter.Write($cacertBytes)
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($header))
                    $streamWriter.Write([System.IO.File]::ReadAllBytes($CustomCAPath))
                    $streamWriter.Flush()
                    $cacertBytes = $stream.ToArray()
                } finally {
                    $streamWriter.Dispose()
                }
            } finally {
                $stream.Dispose()
            }
        }
        Write-Verbose "Saving CA file"
        if ($null -eq $CAPath -or $CAPath -eq '') {
            $CAPath = Join-Path -Path $installedVersion.ActualFolder -ChildPath ssl | Join-Path -ChildPath cacert.pem
        } else {
            $CAPath = [System.IO.Path]::GetFullPath($CAPath)
       }
       $caFolder = Split-Path -LiteralPath $CAPath
       if (-Not(Test-Path -Path $caFolder -PathType Container)) {
           New-Item -Path $caFolder -ItemType Directory | Out-Null
        }
        Set-Content -Path $CAPath -Value $cacertBytes -Encoding Byte
        $iniPath = $phpVersion.IniPath
        $iniValue = Get-PhpIniKey -Key 'curl.cainfo' -Path $iniPath
        if ($iniValue -eq $CAPath) {
            Write-Verbose "curl.cainfo did not require to be updated"
        } else {
            Set-PhpIniKey -Key 'curl.cainfo' -Value $CAPath -Path $iniPath
            Write-Verbose "curl.cainfo updated in php.ini"
        }
        $iniValue = Get-PhpIniKey -Key 'openssl.cafile' -Path $iniPath
        if ($iniValue -eq $CAPath) {
            Write-Verbose "openssl.cafile did not require to be updated"
        } else {
            Set-PhpIniKey -Key 'openssl.cafile' -Value $CAPath -Path $iniPath
            Write-Verbose "openssl.cafile updated in php.ini"
        }
    }
    end {
    }
}
