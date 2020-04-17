function Get-XdebugExtension() {
    <#
    .Synopsis
    Get the latest Xdebug version available on Xdebug website.

    .Parameter Version
    Specify the version of the extension (it can be for example '2.6.0', '2.6', '2').

    .Parameter Stability
    The stability flag of the package: one of 'stable', 'beta', 'alpha', 'devel' or 'snapshot'.

    .Parameter StabilityOperator
    The stability operator: one of '>=', or '=='.

    #>
    [OutputType([PSObject])]
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want the extensions')]
        [ValidateNotNull()]
        [PhpVersionInstalled]$PhpVersion,
        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidatePattern('^(\d+(\.\d+){0,2})?$')]
        [string] $Version,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $Stability,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateSet('>=', '==')]
        [string] $StabilityOperator
    )
    switch ($Stability) {
        $Script:PEARSTATE_STABLE {
            $stabilityRxChunk = ''
        }
        $Script:PEARSTATE_BETA {
            switch ($StabilityOperator) {
                '==' {
                    $stabilityRxChunk = '(?:RC|beta)'
                }
                default {
                    $stabilityRxChunk = '(?:RC|beta)?'
                }
            }
        }
        default {
            switch ($StabilityOperator) {
                '==' {
                    $stabilityRxChunk = '(?:alpha)'
                }
                default {
                    $stabilityRxChunk = '(?:RC|alpha|beta)?'
                }
            }
        }
    }
    $result = $null
    if ($Script:PARSE_XDEBUG_WEBSITE) {
        Write-Verbose 'Analyzing xdebug download page'
        $downloadPageUrl = 'https://xdebug.org/download/historical'
        $downloadLinkRx = '^.*/php_xdebug-({0}(?:\.\d+)*){1}\d*-{2}-vc{3}{4}{5}\.dll$' -f @(
            @('\d+', [System.Text.RegularExpressions.Regex]::Escape($Version))[$Version -ne ''],
            $stabilityRxChunk,
            [System.Text.RegularExpressions.Regex]::Escape($PhpVersion.MajorMinorVersion),
            $PhpVersion.VCVersion,
            @('-nts', '')[$PhpVersion.ThreadSafe]
            @('', '-x86_64')[$PhpVersion.Architecture -eq 'x64']
        )
        $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUrl
        foreach ($link in $webResponse.Links) {
            if ('Href' -in $link.PSobject.Properties.Name) {
                $linkUrl = [Uri]::new([Uri]$downloadPageUrl, $link.Href).AbsoluteUri
                $linkUrlMatch = $linkUrl | Select-String -Pattern $downloadLinkRx
                if ($null -ne $linkUrlMatch) {
                    $result = @{PackageVersion = $linkUrlMatch.Matches[0].Groups[1].Value; PackageArchiveUrl = $linkUrl }
                    break
                }
            }
        }
    }
    $result
}
