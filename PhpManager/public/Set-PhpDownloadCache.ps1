Function Set-PhpDownloadCache
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
    Param (
        [Parameter(Mandatory = $False, Position = 0, HelpMessage = 'The path to a local directory; if empty, the download cache will be disabled')]
        [string]$Path,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'If set and not ''No'', this setting should be persisted for the current user (''CurrentUser''), for any user (''AllUsers'')')]
        [ValidateSet('No', 'CurrentUser', 'AllUsers')]
        [string] $Persist = 'No'
    )
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $Path = ''
        } Else {
            $Path = [System.IO.Path]::GetFullPath($Path)
            If (Test-Path -LiteralPath $Path -PathType Leaf) {
                Throw "$Path is an existing file: the path of download cache must be a directory"
            }
            If (-Not(Test-Path -LiteralPath $Path -PathType Container)) {
                New-Item -Path $Path -ItemType Directory | Out-Null
            }
        }
        If ($Persist -ne 'No') {
            Set-PhpManagerConfigurationKey -Key 'DOWNLOADCACHE_PATH' -Value $(If ($Path -eq '') { $null } Else { $Path }) -Scope $Persist
        }
        Set-Variable -Scope Script -Name 'DOWNLOADCACHE_PATH' -Value $Path -Force
    }
    End {
    }
}
