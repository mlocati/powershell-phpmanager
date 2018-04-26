Function Get-PhpDownloadCache
{
    <#
    .Synopsis
    Gets the path to a local directory where downloaded files should be cached.

    .Example
    Get-PhpDownloadCache

    .Outputs
    [string]
    #>
    Param (
    )
    Begin {
    }
    Process {
    }
    End {
        $Script:DOWNLOADCACHE_PATH
    }
}
