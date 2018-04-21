Function Compare-PhpVersion
{
    <#
    .Synopsis
    Compares two PhpVersion instances.

    .Parameter A
    The first PhpVersion instance to compare.

    .Parameter B
    The second PhpVersion instance to compare.

    .Outputs
    int
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The first PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PSObject]$A,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The second PhpVersion instance to compare')]
        [ValidateNotNull()]
        [PSObject]$B
    )
    Begin {
        $cmp = $null
    }
    Process {
        If ($A.ComparableVersion -lt $B.ComparableVersion) {
            $cmp = -1
        }
        ElseIf ($A.ComparableVersion -gt $B.ComparableVersion) {
            $cmp = 1
        } Else {
            If ($A.Architecture -gt $B.Architecture) {
                $cmp = -1
            } ElseIf ($A.Architecture -lt $B.Architecture) {
                $cmp = -1
            } Else {
                If ($A.ThreadSafe -and -Not $B.ThreadSafe) {
                    $cmp = -1
                } ElseIf ($B.ThreadSafe -and -Not $A.ThreadSafe) {
                    $cmp = 1
                } Else {
                    $cmp = 0
                }
            }
        }
    }
    End {
        $cmp
    }
}
