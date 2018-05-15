function Set-PhpDownloadCache
{
    <#
    .Synopsis
    Sets the path to a local directory where downloaded files should be cached.

    .Parameter Path
    The path to a local directory.
    If Path does not exist, it will be created.
    If Path is not specified (or if it's an empty directory), the cache will be disabled.

    .Parameter Persist
    If set and not 'No', this setting should be persisted for the current user ('CurrentUser'), for any user ('AllUsers').

    .Example
    Set-PhpDownloadCache C:\Download\Cache

    .Example
    Set-PhpDownloadCache C:\Download\Cache CurrentUser

    .Example
    Set-PhpDownloadCache C:\Download\Cache AllUsers

    .Example
    Set-PhpDownloadCache

    .Example
    Set-PhpDownloadCache '' CurrentUser

    .Example
    Set-PhpDownloadCache '' AllUsers
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path to a local directory; if empty, the download cache will be disabled')]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'If set and not ''No'', this setting should be persisted for the current user (''CurrentUser''), for any user (''AllUsers'')')]
        [ValidateSet('No', 'CurrentUser', 'AllUsers')]
        [string] $Persist = 'No'
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $Path = ''
        } else {
            $Path = [System.IO.Path]::GetFullPath($Path)
            if (Test-Path -LiteralPath $Path -PathType Leaf) {
                throw "$Path is an existing file: the path of download cache must be a directory"
            }
            if (-Not(Test-Path -LiteralPath $Path -PathType Container)) {
                New-Item -Path $Path -ItemType Directory | Out-Null
            }
        }
        if ($Persist -ne 'No') {
            Set-PhpManagerConfigurationKey -Key 'DOWNLOADCACHE_PATH' -Value $(if ($Path -eq '') { $null } else { $Path }) -Scope $Persist
        }
        Set-Variable -Scope Script -Name 'DOWNLOADCACHE_PATH' -Value $Path -Force
    }
    end {
    }
}
