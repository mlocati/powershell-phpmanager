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
        If ($null -eq $Script:DOWNLOADCACHE_PATH) {
            $path = Get-PhpManagerConfigurationKey -Key 'DOWNLOADCACHE_PATH'
            If ($null -eq $path) {
                $path = ''
            }
            Set-Variable -Scope Script -Name 'DOWNLOADCACHE_PATH' -Value $path -Force
        }
    }
    End {
        $Script:DOWNLOADCACHE_PATH
    }
}
