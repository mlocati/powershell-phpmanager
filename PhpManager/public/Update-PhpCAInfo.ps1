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

    .Parameter Source
    The source of the root CA certificates. It can be:
    - 'Curl' [default] to fetch the certificates from the cURL website (https://curl.haxx.se)
    - 'LocalMachine' to fetch the certificates from the Windows repository of the local machine
    - 'CurrentUser' to fetch the certificates from the Windows repository of the current user

    .Parameter SkipChecksumCheck
    Use this switch to skip checking the checksum of the CA list fetched from curl website.
    This may be used to ignore a mismatch error which is false positive if the CA is updated recently and the CA list is cached by the CDN.

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
        [string] $CustomCAPath = '',
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'The source of the CA certificates')]
        [ValidateNotNull()]
        [ValidateSet('Curl', 'LocalMachine', 'CurrentUser')]
        [string] $Source = 'Curl',
        [switch] $SkipChecksumCheck
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
        switch -Regex ($Source) {
            '^(LocalMachine|CurrentUser)$' {
                $cacertBytes = Get-CACertFromSystem -Source $Source
            }
            'Curl' {
                $cacertBytes = Get-CACertFromCurl -SkipChecksumCheck $SkipChecksumCheck
            }
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
                    $streamWriter.Write([byte[]]$cacertBytes)
                    $streamWriter.Write([System.Text.Encoding]::ASCII.GetBytes($header))
                    $streamWriter.Write([System.IO.File]::ReadAllBytes($CustomCAPath))
                    $streamWriter.Flush()
                    $stream.Position = 0
                    $cacertBytes = $stream.ToArray()
                } finally {
                    $streamWriter.Dispose()
                }
            } finally {
                $stream.Dispose()
            }
        }
        if ($null -eq $CAPath -or $CAPath -eq '') {
            $CAPath = Join-Path -Path $phpVersion.ActualFolder -ChildPath ssl | Join-Path -ChildPath cacert.pem
        } else {
            $CAPath = [System.IO.Path]::GetFullPath($CAPath)
       }
       Write-Verbose "Saving CA file as $CAPath"
       $caFolder = Split-Path -LiteralPath $CAPath
       if (-Not(Test-Path -Path $caFolder -PathType Container)) {
           New-Item -Path $caFolder -ItemType Directory | Out-Null
        }
        if ($PSVersionTable.PSVersion -ge '6.0') {
            Set-Content -Path $CAPath -Value $cacertBytes -AsByteStream
        } else {
            Set-Content -Path $CAPath -Value $cacertBytes -Encoding Byte
        }
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
