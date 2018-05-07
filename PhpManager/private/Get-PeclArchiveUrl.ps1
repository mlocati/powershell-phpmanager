function Get-PeclArchiveUrl
{
    <#
    .Synopsis
    Gets the list of DLLs available for a PECL package.

    .Parameter PackageHandle
    The handle of the package.

    .Parameter PackageVersion
    The version of the package.

    .Parameter PhpVersion
    The PhpVersion instance for which you want the PECL packages.

    .Parameter MinimumStability
    The minimum stability of the package.

    .Outputs
    System.Array
    #>
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PackageHandle,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PackageVersion,
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNull()]
        [ValidateScript({ $_ -is [PhpVersion] })]
        [psobject] $PhpVersion,
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MinimumStability = 'stable'
    )
    begin {
        $result = @()
    }
    process {
        # https://github.com/php/web-pecl/blob/467593b248d4603a3dee2ecc3e61abfb7434d24d/include/pear-win-package.php
        $handleLC = $PackageHandle.ToLowerInvariant();
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
        } catch {
            Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
        }
        $rxMatch = '/php_' + [regex]::Escape($PackageHandle)
        $rxMatch += '-' + [regex]::Escape($PackageVersion)
        $rxMatch += '-' + [regex]::Escape('' + $PhpVersion.ComparableVersion.Major + '.' + $PhpVersion.ComparableVersion.Minor)
        $rxMatch += '-' + $(if ($PhpVersion.ThreadSafe) { 'ts' } else { 'nts' } )
        $rxMatch += '-vc' + $PhpVersion.VCVersion
        $rxMatch += '-' + [regex]::Escape($PhpVersion.Architecture)
        $rxMatch += '\.zip$'
        $urls = @("https://windows.php.net/downloads/pecl/releases/$handleLC/$PackageVersion")
        if ($MinimumStability -eq $Script:PEARSTATE_SNAPSHOT) {
            $urls += "https://windows.php.net/downloads/pecl/snaps/$handleLC/$PackageVersion"
        }
        foreach ($url in $urls) {
            try {
                $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $url
            } catch [System.Net.WebException] {
                if ($_.Exception -and $_.Exception.Response -and $_.Exception.Response.StatusCode -eq 404) {
                    continue
                }
            }
            foreach ($link in $webResponse.Links) {
                $linkUrl = [Uri]::new([Uri]$url, $link.Href).AbsoluteUri
                $match = $linkUrl | Select-String -Pattern $rxMatch
                if ($match) {
                    $result += $linkUrl
                }
            }
            if ($result.Count -gt 0) {
                break
            }
        }
    }
    end {
        $result
    }
}
