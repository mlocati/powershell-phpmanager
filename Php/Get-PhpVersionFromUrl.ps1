Function Get-PhpVersionFromUrl
{
    <#
    .Synopsis
    Creates a new object representing a PHP version from an PHP download URL.
    
    .Parameter Url
    The PHP download URL (eventually relative to PageUrl)

    .Parameter PageUrl
    The URL of the page where the download link has been retrieved from

    .Parameter ReleaseState
    One of the RELEASESTATE_... constants

    .Outputs
    PSCustomObject

    .Example
    Get-PhpVersionFromUrl '/downloads/releases/php-7.2.4-Win32-VC15-x86.zip' 'https://windows.php.net/downloads/releases/' $Script:RELEASESTATE_RELEASE
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The PHP download URL (eventually relative to PageUrl)')]
        [ValidateNotNull()]
        [string]$Url,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'The URL of the page where the download link has been retrieved from')]
        [string]$PageUrl,
        [Parameter(Mandatory = $False, Position = 2, HelpMessage = 'One of the RELEASESTATE_... constants')]
        [string]$ReleaseState
    )
    Begin {
        $data = @{}
    }
    Process {
        $rxMatch = $Url | Select-String -CaseSensitive -Pattern ('/' + $Script:RX_ZIPARCHIVE + '$')
        $data['BaseVersion'] = $rxMatch.Matches.Groups[1].Value;
        $data['RC'] = $rxMatch.Matches.Groups[2].Value;
        $data['Architecture'] = $rxMatch.Matches.Groups[5].Value;
        $data['ThreadSafe'] = $rxMatch.Matches.Groups[3].Value -ne '-nts';
        $data['VCVersion'] = $rxMatch.Matches.Groups[4].Value;
        $data['ReleaseState'] = $ReleaseState;
        If ($PageUrl -ne $null -and $PageUrl -ne '') {
            $data['DownloadUrl'] = [Uri]::new([Uri]$PageUrl, $Url).AbsoluteUri
        } else {
            $data['DownloadUrl'] = $Url
        }
    }
    End {
        New-PhpVersion $data
    }
}
