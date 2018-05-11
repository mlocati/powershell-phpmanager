function Get-PhpVersionsCompatibility
{
    <#
    .Synopsis
    Checks if two PhpVersion instances are compatible.

    .Parameter A
    The first PhpVersion instance to check.

    .Parameter B
    The second PhpVersion instance to check.

    .Outputs
    bool
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The first PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PhpVersion]$A,
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The second PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PhpVersion]$B
    )
    begin {
        $areCompatible = $null
    }
    process {
        if ($a.Architecture -ne $b.Architecture -or $a.ThreadSafe -ne $b.ThreadSafe) {
            $areCompatible = $False
        } elseif ($a.ComparableVersion.Major -ne $b.ComparableVersion.Major -or $a.ComparableVersion.Minor -ne $b.ComparableVersion.Minor) {
            $areCompatible = $False
        } else {
            $areCompatible = $True
        }
    }
    end {
        $areCompatible
    }
}
