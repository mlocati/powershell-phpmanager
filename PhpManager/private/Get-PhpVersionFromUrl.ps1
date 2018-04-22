Function Get-PhpVersionFromUrl
{
    <#
    .Synopsis
    Creates a new object representing a PHP version from an PHP download URL.

    .Parameter Url
    The PHP download URL (eventually relative to PageUrl).

    .Parameter PageUrl
    The URL of the page where the download link has been retrieved from.

    .Parameter ReleaseState
    One of the $Script:RELEASESTATE_... constants.

    .Outputs
    PSCustomObject

    .Example
    Get-PhpVersionFromUrl '/downloads/releases/php-7.2.4-Win32-VC15-x86.zip' 'https://windows.php.net/downloads/releases/' $Script:RELEASESTATE_RELEASE
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The PHP download URL (eventually relative to PageUrl)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Url,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'The URL of the page where the download link has been retrieved from')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$PageUrl,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'One of the $Script:RELEASESTATE_... constants')]
        [ValidateSet('QA', 'Release', 'Archive')]
        [string]$ReleaseState
    )
    Begin {
        $data = @{}
    }
    Process {
        $match = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        $data['BaseVersion'] = $match.Matches.Groups[1].Value;
        $data['RC'] = $match.Matches.Groups[2].Value;
        $data['Architecture'] = $match.Matches.Groups[5].Value;
        $data['ThreadSafe'] = $match.Matches.Groups[3].Value -ne '-nts';
        $data['VCVersion'] = $match.Matches.Groups[4].Value;
        $data['ReleaseState'] = $ReleaseState;
        If ($null -ne $PageUrl -and $PageUrl -ne '') {
            $data['DownloadUrl'] = [Uri]::new([Uri]$PageUrl, $Url).AbsoluteUri
        } else {
            $data['DownloadUrl'] = $Url
        }
    }
    End {
        New-PhpVersion $data
    }
}
