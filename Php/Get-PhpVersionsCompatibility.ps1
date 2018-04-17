Function Get-PhpVersionsCompatibility
{
    <#
    .Synopsis
    Checks if two PHP version objects are compatible.
    
    .Parameter A
    The first PHP version object to check

    .Parameter B
    The second PHP version object to check

    .Outputs
    bool
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The first PHP version object to compare')]
        [ValidateNotNull()]
        [PSObject]$A,
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The first PHP version object to compare')]
        [ValidateNotNull()]
        [PSObject]$B
    )
    Begin {
        $areCompatible = $null
    }
    Process {
        if ($a.Architecture -ne $b.Architecture -or $a.ThreadSafe -ne $b.ThreadSafe) {
            $areCompatible = $False
        } elseif ($a.ComparableVersion.Major -ne $b.ComparableVersion.Major -or $a.ComparableVersion.Minor -ne $b.ComparableVersion.Minor) {
            $areCompatible = $False
        } else {
            $areCompatible = $True
        }
    }
    End {
        $areCompatible
    }
}
