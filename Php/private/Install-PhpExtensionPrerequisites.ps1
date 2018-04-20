function Install-PhpExtensionPrerequisites() {
    <#
    .Synopsis
    Installs the prerequisites of a PHP extension.

    .Parameter PhpVersion
    The PhpVersion instance the extension will be installed for.

    .Parameter Extension
    The PhpExtension instance representing the extension.
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [psobject] $PhpVersion,
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNull()]
        [psobject] $Extension
    )
    Begin {
    }
    Process {
        Write-Host ('Checking prerequisites for {0}' -f $Extension.Name)
        switch ($Extension.Handle) {
            imagick {
                $rxSearch = '/ImageMagick-[\d\.\-]+-vc' + $PhpVersion.VCVersion + '-' + $PhpVersion.Architecture + '\.zip$'
                $pageUrl = 'https://windows.php.net/downloads/pecl/deps/'
                Try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
                }
                Catch {
                }
                $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $pageUrl
                $zipUrl = $null
                ForEach ($link In $webResponse.Links) {
                    $fullUrl = [Uri]::new([Uri]$pageUrl, $link.Href).AbsoluteUri
                    If ($fullUrl -match $rxSearch) {
                        $zipUrl = $fullUrl
                        break
                    }
                }
                If ($zipUrl -eq $null) {
                    Throw ('Unable to find the imagick package dependencies on {0} for {1}' -f $pageUrl, $PhpVersion.DisplayName)
                }
                $zipFile = Get-ZipFromUrl -Url $zipUrl
                Try {
                    $tempFolder = New-TempDirectory
                    Try {
                        Expand-Archive -LiteralPath $zipFile -DestinationPath $tempFolder
                        $phpFolder = [System.IO.Path]::GetDirectoryName($PhpVersion.ExecutablePath)
                        Get-ChildItem -LiteralPath $tempFolder -Recurse -File -Filter *.dll `
                            | Where-Object {$_.Name -like 'CORE_RL_*.dll' -or $_.Name -like 'IM_MOD_RL_*.dll' } `
                            | Move-Item -Force -Destination $phpFolder
                    }
                    Finally {
                        Try {
                            Remove-Item -Path $tempFolder -Recurse -Force
                        }
                        Catch {
                        }
                    }                                
                }
                Finally {
                    Try {
                        Remove-Item -Path $zipFile
                    }
                    Catch {
                    }
                }
            }
        }
    }
    End {
    }
}
