Function Compare-PhpVersions
{
    <#
    .Synopsis
    Compares two PHP version objects.

    .Parameter A
    The first PHP version object to compare

    .Parameter B
    The second PHP version object to compare

    .Outputs
    int
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
        $cmp = $null
    }
    Process {
        if ($A.ComparableVersion -lt $B.ComparableVersion) {
            $cmp = -1
        }
        elseif ($A.ComparableVersion -gt $B.ComparableVersion) {
            $cmp = 1
        } else {
            if ($A.Architecture -gt $B.Architecture) {
                $cmp = -1
            } elseif ($A.Architecture -lt $B.Architecture) {
                $cmp = -1
            } else {
                if ($A.ThreadSafe -and -Not $B.ThreadSafe) {
                    $cmp = -1
                } elseif ($B.ThreadSafe -and -Not $A.ThreadSafe) {
                    $cmp = 1
                } else {
                    $cmp = 0
                }
            }
        }
    }
    End {
        $cmp
    }
}
