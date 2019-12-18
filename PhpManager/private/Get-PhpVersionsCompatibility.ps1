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
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The first PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PhpVersion]$A,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'The second PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PhpVersion]$B,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Skip the check about the version?')]
        [bool]$SkipVersionCheck = $false

    )
    begin {
        $areCompatible = $null
    }
    process {
        if ($A.Architecture -ne $B.Architecture -or $A.ThreadSafe -ne $B.ThreadSafe) {
            $areCompatible = $false
        } elseif (-not($SkipVersionCheck) -and ($A.ComparableVersion.Major -ne $B.ComparableVersion.Major -or $A.ComparableVersion.Minor -ne $B.ComparableVersion.Minor)) {
            $areCompatible = $false
        } else {
            $areCompatible = $true
        }
    }
    end {
        $areCompatible
    }
}
