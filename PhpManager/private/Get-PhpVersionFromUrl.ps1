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
        [ValidateSet('QA', 'Release', 'Archive')]
        [string] $ReleaseState,
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$PageUrl
    )
    begin {
        $result = $null
    }
    process {
        $match = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        if ($null -eq $match) {
            throw "Unrecognized PHP ZIP archive url: $Url"
        }
        $data = @{}
        $data.Version = $match.Matches.Groups[1].Value;
        $data.UnstabilityLevel = $match.Matches.Groups[2].Value;
        $data.UnstabilityVersion = $match.Matches.Groups[3].Value;
        $data.Architecture = $match.Matches.Groups[6].Value;
        $data.ThreadSafe = $match.Matches.Groups[4].Value -ne '-nts';
        $data.VCVersion = $match.Matches.Groups[5].Value;
        $data.ReleaseState = $ReleaseState;
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
