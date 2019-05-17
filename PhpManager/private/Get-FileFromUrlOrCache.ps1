function Get-FileFromUrlOrCache
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
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url,
        [Parameter(Mandatory = $false, Position = 1)]
        [string] $CachedFileName
    )
    begin {
        $localFile = $null
        $fromCache = $null
    }
    process {
        $extension = ''
        if ($null -ne $CachedFileName -and $CachedFileName -ne '') {
            $match = $CachedFileName | Select-String -Pattern '.(\.[A-Za-z0-9_\-]+)$'
            if ($match) {
                $extension = $match.Matches.Groups[1].Value
            }
        } else {
            $CachedFileName = ''
            $match = $Url | Select-String -Pattern '^[^:]+:/+[^?#/]+/(?:[^?#/]*/)*([^?#/]+)(?:$|^|#)'
            if ($match) {
                $nameFromUrl = $match.Matches.Groups[1].Value
                $match = $nameFromUrl | Select-String -Pattern '.(\.[A-Za-z0-9_\-]+)$'
                if ($match) {
                    $extension = $match.Matches.Groups[1].Value
                }
                if ($nameFromUrl -imatch '^[a-z0-9_\-][a-z0-9_\-\.]*[a-z0-9_\-]$') {
                    $CachedFileName = $nameFromUrl;
                }
            }
            if ($CachedFileName -eq '') {
                $stream = New-Object System.IO.MemoryStream
                try {
                    $streamWriter = New-Object -TypeName System.IO.BinaryWriter -ArgumentList @($stream)
                    try {
                        $streamWriter.Write([System.Text.Encoding]::UTF8.GetBytes($Url))
                        $streamWriter.Flush()
                        $stream.Position = 0
                        $hash = Get-FileHash -InputStream $stream -Algorithm SHA1
                        $CachedFileName = $hash.Hash
                    } finally {
                        $streamWriter.Dispose()
                    }
                } finally {
                    $stream.Dispose()
                }
            }
        }
        $downloadCachePath = Get-PhpDownloadCache
        if ($downloadCachePath -eq '') {
            $fullCachePath = ''
        } else {
            if (-Not(Test-Path -LiteralPath $downloadCachePath -PathType Container)) {
                New-Item -Path $downloadCachePath -ItemType Directory | Out-Null
            }
            $fullCachePath = Join-Path -Path $downloadCachePath -ChildPath $CachedFileName
        }
        if ($fullCachePath -ne '' -and (Test-Path -LiteralPath $fullCachePath -PathType Leaf)) {
            Write-Verbose "Using cached file for $Url"
            $localFile = $fullCachePath
            $fromCache = $true
        } else {
            $temporaryFile = Get-TemporaryFileWithExtension -Extension $extension
            try {
                Set-NetSecurityProtocolType
                Write-Verbose "Downloading from $Url"
                Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $temporaryFile
                if ($fullCachePath -ne '') {
                    Move-Item -LiteralPath $temporaryFile -Destination $fullCachePath
                    $localFile = $fullCachePath
                    $fromCache = $true
                } else {
                    $localFile = $temporaryFile
                    $fromCache = $false
                }
            } catch {
                try {
                    Remove-Item -LiteralPath $temporaryFile
                } catch {
                    Write-Debug 'Failed to remove a temporary file'
                }
                throw
            }
        }
    }
    end {
        $localFile
        $fromCache
    }
}
