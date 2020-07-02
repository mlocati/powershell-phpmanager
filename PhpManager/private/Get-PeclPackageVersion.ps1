function Get-PeclPackageVersion
{
    <#
    .Synopsis
    Gets the list of available versions for a PECL package.

    .Parameter Handle
    The handle of the PECL package.

    .Parameter Version
    Specify the version of the extension (it can be for example '2.6.0', '2.6', '2').

    .Parameter MinimumStability
    The minimum stability flag of the package: one of 'stable' (default), 'beta', 'alpha', 'devel' or 'snapshot'.

    .Parameter MaximumStability
    The maximum stability flag of the package: one of 'stable' (default), 'beta', 'alpha', 'devel' or 'snapshot'.

    .Outputs
    System.Array
    #>
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_\-]*$')]
        [string] $Handle,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidatePattern('^(\d+(\.\d+){0,2})?$')]
        [string] $Version,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MinimumStability = 'stable',
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MaximumStability = 'stable'
    )
    begin {
        $result = @()
    }
    process {
        switch ($MinimumStability) {
            $Script:PEARSTATE_SNAPSHOT { $minimumStabilityInt = 0 }
            $Script:PEARSTATE_DEVEL { $minimumStabilityInt = 1 }
            $Script:PEARSTATE_ALPHA { $minimumStabilityInt = 2 }
            $Script:PEARSTATE_BETA { $minimumStabilityInt = 3 }
            $Script:PEARSTATE_STABLE { $minimumStabilityInt = 4 }
            default { throw "Unrecognized value of MinimumStability: $MinimumStability" }
        }
        switch ($MaximumStability) {
            $Script:PEARSTATE_SNAPSHOT { $maximumStabilityInt = 0 }
            $Script:PEARSTATE_DEVEL { $maximumStabilityInt = 1 }
            $Script:PEARSTATE_ALPHA { $maximumStabilityInt = 2 }
            $Script:PEARSTATE_BETA { $maximumStabilityInt = 3 }
            $Script:PEARSTATE_STABLE { $maximumStabilityInt = 4 }
            default { throw "Unrecognized value of MaximumStability: $MaximumStability" }
        }
        if ($maximumStabilityInt -lt $minimumStabilityInt) {
            throw "The maximim stability ($MaximumStability) is lower than the minimum stability ($MinimumStability)"
        }
        if ($null -eq $Version -or $Version -eq '') {
            $rxVersion = $null
        } else {
            $rxVersion = '^' + [regex]::Escape($Version) + '($|\.|[a-z])'
        }
        # https://pear.php.net/manual/en/core.rest.php
        $handleLC = $Handle.ToLowerInvariant()
        Set-NetSecurityProtocolType
        $xmlDocument = Invoke-RestMethod -Method Get -Uri ($Script:URL_PECLREST_1_0 + "r/$handleLC/allreleases.xml")
        $xmlVersions = @($xmlDocument | Select-Xml -XPath '/ns:a/ns:r' -Namespace @{'ns' = $xmlDocument.DocumentElement.NamespaceURI} | Select-Object -ExpandProperty Node)
        foreach ($xmlVersion in $xmlVersions) {
            switch ($xmlVersion.s) {
                $Script:PEARSTATE_SNAPSHOT { $stabilityInt = 0 }
                $Script:PEARSTATE_DEVEL { $stabilityInt = 1 }
                $Script:PEARSTATE_ALPHA { $stabilityInt = 2 }
                $Script:PEARSTATE_BETA { $stabilityInt = 3 }
                $Script:PEARSTATE_STABLE { $stabilityInt = 4 }
                default { throw ('Unrecognized value of stability read in XML' + $xmlVersion.s) }
            }
            if ($stabilityInt -ge $minimumStabilityInt) {
                if ($stabilityInt -le $maximumStabilityInt) {
                    if ($null -eq $rxVersion -or $xmlVersion.v -match $rxVersion) {
                        $result += $xmlVersion.v
                    }
                }
            }
        }
    }
    end {
        $result
    }
}
