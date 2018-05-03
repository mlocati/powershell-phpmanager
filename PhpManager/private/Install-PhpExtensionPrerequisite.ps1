function Install-PhpExtensionPrerequisite() {
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
        [PhpVersionInstalled] $PhpVersion,
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNull()]
        [PhpVersionInstalled] $Extension
    )
    Begin {
    }
    Process {
        Write-Output ('Checking prerequisites for {0}' -f $Extension.Name)
        switch ($Extension.Handle) {
            imagick {
                $rxSearch = '/ImageMagick-[\d\.\-]+-vc' + $PhpVersion.VCVersion + '-' + $PhpVersion.Architecture + '\.zip$'
                $pageUrl = 'https://windows.php.net/downloads/pecl/deps/'
                Try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
                }
                Catch {
                    Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
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
                If ($null -eq $zipUrl) {
                    Throw ('Unable to find the imagick package dependencies on {0} for {1}' -f $pageUrl, $PhpVersion.DisplayName)
                }
                Write-Output "Downloading and extracting $zipUrl"
                $zipFile, $keepZipFile = Get-FileFromUrlOrCache -Url $zipUrl
                Try {
                    $tempFolder = New-TempDirectory
                    Try {
                        Try {
                            Expand-Archive -LiteralPath $zipFile -DestinationPath $tempFolder
                        }
                        Catch {
                            $keepZipFile = $false
                            Throw
                        }
                        Get-ChildItem -LiteralPath $tempFolder -Recurse -File -Filter *.dll `
                            | Where-Object {$_.Name -like 'CORE_RL_*.dll' -or $_.Name -like 'IM_MOD_RL_*.dll' } `
                            | Move-Item -Force -Destination $PhpVersion.ActualFolder
                    }
                    Finally {
                        Try {
                            Remove-Item -Path $tempFolder -Recurse -Force
                        }
                        Catch {
                            Write-Debug 'Failed to remove temporary folder'
                        }
                    }
                }
                Finally {
                    If (-Not($keepZipFile)) {
                        Try {
                            Remove-Item -Path $zipFile
                        }
                        Catch {
                            Write-Debug 'Failed to remove temporary zip file'
                        }
                    }
                }
            }
        }
    }
    End {
    }
}
