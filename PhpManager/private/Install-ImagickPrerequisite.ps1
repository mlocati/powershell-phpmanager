function Install-ImagickPrerequisite() {
    <#
    .Synopsis
    Installs the prerequisites for the imagick PHP extension.

    .Parameter PhpVersion
    The PhpVersion instance the extension will be installed for.

    .Parameter InstallPath
    The path to a directory where the prerequisites should be installed.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [PhpVersionInstalled] $PhpVersion,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $InstallPath
    )
    begin {
    }
    process {
        $rxSearch = '/ImageMagick-[\d\.\-]+-(VC|vc|vs)' + $PhpVersion.VCVersion + '-' + $PhpVersion.Architecture + '\.zip$'
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
                $items = Get-ChildItem -LiteralPath $tempFolder -Recurse -File -Filter *.dll ` | Where-Object { $_.Name -like 'CORE_RL_*.dll' -or $_.Name -like 'IM_MOD_RL_*.dll' }
                foreach ($item in $items) {
                    $destinationPath = [System.IO.Path]::Combine($InstallPath, $item.Name)
                    Move-Item -LiteralPath $item.FullName -Destination $destinationPath -Force
                    try {
                        Reset-Acl -Path $destinationPath
                    } catch {
                        Write-Debug -Message "Failed to reset the ACL for $($destinationPath): $($_.Exception.Message)"
                    }
                }
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
    end {
    }
}
