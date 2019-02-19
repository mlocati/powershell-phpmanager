function Install-PhpExtensionPrerequisite() {
    <#
    .Synopsis
    Installs the prerequisites of a PHP extension.

    .Parameter PhpVersion
    The PhpVersion instance the extension will be installed for.

    .Parameter Extension
    The PhpExtension instance representing the extension.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [PhpVersionInstalled] $PhpVersion,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [PhpExtension] $Extension
    )
    begin {
    }
    process {
        Write-Verbose ('Checking prerequisites for {0}' -f $Extension.Name)
        switch ($Extension.Handle) {
            imagick {
                $rxSearch = '/ImageMagick-[\d\.\-]+-vc' + $PhpVersion.VCVersion + '-' + $PhpVersion.Architecture + '\.zip$'
                $pageUrl = 'https://windows.php.net/downloads/pecl/deps/'
                Set-NetSecurityProtocolType
                $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $pageUrl
                $zipUrl = $null
                foreach ($link in $webResponse.Links) {
                    $fullUrl = [Uri]::new([Uri]$pageUrl, $link.Href).AbsoluteUri
                    if ($fullUrl -match $rxSearch) {
                        $zipUrl = $fullUrl
                        break
                    }
                }
                if ($null -eq $zipUrl) {
                    throw ('Unable to find the imagick package dependencies on {0} for {1}' -f $pageUrl, $PhpVersion.DisplayName)
                }
                Write-Verbose "Downloading and extracting $zipUrl"
                $zipFile, $keepZipFile = Get-FileFromUrlOrCache -Url $zipUrl
                try {
                    $tempFolder = New-TempDirectory
                    try {
                        try {
                            Expand-ArchiveWith7Zip -ArchivePath $zipFile -DestinationPath $tempFolder
                        } catch {
                            $keepZipFile = $false
                            throw
                        }
                        Get-ChildItem -LiteralPath $tempFolder -Recurse -File -Filter *.dll `
                            | Where-Object { $_.Name -like 'CORE_RL_*.dll' -or $_.Name -like 'IM_MOD_RL_*.dll' } `
                            | Move-Item -Force -Destination $PhpVersion.ActualFolder
                    } finally {
                        try {
                            Remove-Item -Path $tempFolder -Recurse -Force
                        } catch {
                            Write-Debug 'Failed to remove temporary folder'
                        }
                    }
                } finally {
                    if (-Not($keepZipFile)) {
                        try {
                            Remove-Item -Path $zipFile
                        } catch {
                            Write-Debug 'Failed to remove temporary zip file'
                        }
                    }
                }
            }
        }
    }
    end {
    }
}
