function Get-PhpDownloadCache
{
    <#
    .Synopsis
    Gets the path to a local directory where downloaded files should be cached.

    .Example
    Get-PhpDownloadCache

    .Outputs
    [string]
    #>
    [OutputType([string])]
    param (
    )
    begin {
    }
    process {
        if ($null -eq $Script:DOWNLOADCACHE_PATH) {
            $path = Get-PhpManagerConfigurationKey -Key 'DOWNLOADCACHE_PATH'
            if ($null -eq $path) {
                $path = ''
            }
            Set-Variable -Scope Script -Name 'DOWNLOADCACHE_PATH' -Value $path -Force
        }
    }
    end {
        $Script:DOWNLOADCACHE_PATH
    }
}
