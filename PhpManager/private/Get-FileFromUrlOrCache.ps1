Function Get-FileFromUrlOrCache
{
    <#
    .Synopsis
    Gets a file from the download cache or (if unavailable) download and cache it (if the cache is enabled)

   .Parameter Url
    The URL to be downloaded from.

    .Parameter CachedFileName
    The name of the file to be used to store the downloaded resource in the cache.

    .Example
    Get-FileFromUrlOrCache 'http://www.example.com/test.zip'

    .Example
    Get-FileFromUrlOrCache 'http://www.example.com/test.zip' 'cached-file-name.zip'

    .Outputs
    [System.Array]
    #>
    [OutputType([string], [bool])]
    Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url,
        [Parameter(Mandatory = $False, Position = 1)]
        [string] $CachedFileName
    )
    Begin {
        $localFile = $null
        $fromCache = $null
    }
    Process {
        $extension = ''
        If ($null -ne $CachedFileName -and $CachedFileName -ne '') {
            $match = $CachedFileName | Select-String -Pattern '.(\.[A-Za-z0-9_\-]+)$'
            If ($match) {
                $extension = $match.Matches.Groups[1].Value
            }
        } Else {
            $CachedFileName = ''
            $match = $Url | Select-String -Pattern '^[^:]+:/+[^?#/]+/(?:[^?#/]*/)*([^?#/]+)(?:$|^|#)'
            If ($match) {
                $nameFromUrl = $match.Matches.Groups[1].Value
                $match = $nameFromUrl | Select-String -Pattern '.(\.[A-Za-z0-9_\-]+)$'
                If ($match) {
                    $extension = $match.Matches.Groups[1].Value
                }
                If ($nameFromUrl -imatch '^[a-z0-9_\-][a-z0-9_\-\.]*[a-z0-9_\-]$') {
                    $CachedFileName = $nameFromUrl;
                }
            }
            If ($CachedFileName -eq '') {
                $stream = New-Object System.IO.MemoryStream
                Try {
                    $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                    Try {
                        $streamWriter.Write([System.Text.Encoding]::UTF8.GetBytes($Url))
                        $streamWriter.Flush()
                        $stream.Position = 0
                        $hash = Get-FileHash -InputStream $stream -Algorithm SHA1
                        $CachedFileName = $hash.Hash
                    }
                    Finally {
                        $streamWriter.Dispose()
                    }
                }
                Finally {
                    $stream.Dispose()
                }
            }
        }
        $downloadCachePath = Get-PhpDownloadCache
        If ($downloadCachePath -eq '') {
            $fullCachePath = ''
        } Else {
            If (-Not(Test-Path -LiteralPath $downloadCachePath -PathType Container)) {
                New-Item -Path $downloadCachePath -ItemType Directory | Out-Null
            }
            $fullCachePath = Join-Path -Path $downloadCachePath -ChildPath $CachedFileName
        }
        If ($fullCachePath -ne '' -and (Test-Path -LiteralPath $fullCachePath -PathType Leaf)) {
            $localFile = $fullCachePath
            $fromCache = $true
        } Else {
            $temporaryFile = Get-TemporaryFileWithExtension -Extension $extension
            Try {
                Try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
                }
                Catch {
                    Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
                }
                Write-Debug "Downloading from $Url"
                Invoke-WebRequest -UseBasicParsing $Url -OutFile $temporaryFile
                If ($fullCachePath -ne '') {
                    Move-Item -LiteralPath $temporaryFile -Destination $fullCachePath
                    $localFile = $fullCachePath
                    $fromCache = $true
                } Else {
                    $localFile = $temporaryFile
                    $fromCache = $false
                }
            } Catch {
                Try {
                    Remove-Item -LiteralPath $temporaryFile
                } Catch {
                    Write-Debug 'Failed to remove a temporary file'
                }
                Throw
            }
        }
    }
    End {
        $localFile
        $fromCache
    }
}
