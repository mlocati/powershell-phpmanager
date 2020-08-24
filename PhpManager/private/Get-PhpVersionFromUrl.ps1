function Get-PhpVersionFromUrl
{
    <#
    .Synopsis
    Gets an instance of PhpVersion by parsing its download URL.

    .Parameter Url
    The PHP download URL (eventually relative to PageUrl).

    .Parameter ReleaseState
    One of the $Script:RELEASESTATE_... constants.

    .Parameter PageUrl
    The URL of the page where the download link has been retrieved from.

    .Outputs
    PhpVersionDownloadable
    #>
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Url,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateSet('QA', 'Release', 'Archive', 'Snapshot')]
        [string] $ReleaseState,
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$PageUrl
    )
    begin {
        $result = $null
    }
    process {
        $data = @{}
        $match = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        if ($null -ne $match) {
            $groups = $match.Matches[0].Groups
            $data.Version = $groups['version'].Value
            $data.UnstabilityLevel = $groups['unstabilityLevel'].Value
            $data.UnstabilityVersion = $groups['unstabilityVersion'].Value
            $data.ThreadSafe = $groups['threadSafe'].Value -ne '-nts'
            $data.VCVersion = $groups['vcVersion'].Value
            $data.Architecture = $groups['architecture'].Value
        } else {
            $match = $Url | Select-String -CaseSensitive -Pattern ($Script:RX_ZIPARCHIVE_SNAPSHOT)
            if ($null -eq $match) {
                $match = $Url | Select-String -CaseSensitive -Pattern ($Script:RX_ZIPARCHIVE_SNAPSHOT_SHIVAMMATHUR)
            }
            if ($null -ne $match) {
                $groups = $match.Matches[0].Groups
                if ($groups['version'].Value -eq '') {
                    $data.Version = 'master'
                } else {
                    $data.Version = $groups['version'].Value
                }
                $data.UnstabilityLevel = $Script:UNSTABLEPHP_SNAPSHOT
                $data.UnstabilityVersion = $null
                $data.ThreadSafe = $groups['threadSafe'].Value -ne 'nts'
                $data.VCVersion = $groups['vcVersion'].Value
                $data.Architecture = $groups['architecture'].Value
            } else {
                throw "Unrecognized PHP ZIP archive url: $Url"
            }
        }
        $data.ReleaseState = $ReleaseState
        if ($null -ne $PageUrl -and $PageUrl -ne '') {
            $data.DownloadUrl = [Uri]::new([Uri]$PageUrl, $Url).AbsoluteUri
        } else {
            $data.DownloadUrl = $Url
        }
        $result = [PhpVersionDownloadable]::new($data)
    }
    end {
        $result
    }
}
