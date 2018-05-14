function Get-Php() {
    <#
    .Synopsis
    Get the details about installed PHP versions.

    .Description
    Get the details a PHP version installed in a specific location, or in all the PHP installations found in the current environment PATH.

    .Parameter Path
    Get the details about PHP installed in this location.
    If omitted we'll look for PHP installed in the current PATH.

    .Outputs
    System.Array
    #>
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path where PHP is installed')]
        [string] $Path
    )
    begin {
        $result = @()
    }
    process {
        if ($null -ne $Path -and $Path -ne '') {
            $result += [PhpVersionInstalled]::FromPath($Path)
        } else {
            $result += [PhpVersionInstalled]::FromEnvironment()
        }
    }
    end {
        $result
    }
}
