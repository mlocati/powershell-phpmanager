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
    Param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path where PHP is installed')]
        [string] $Path
    )
    Begin {
        $result = @()
    }
    Process {
        If ($Path -ne $null -and $Path -ne '') {
            $result += Get-PhpVersionFromPath -Path $Path
        } Else {
            $donePaths = @{}
            ForEach ($pathFromEnv in @($env:Path.split(';'))) {
                $executablePath = [System.IO.Path]::Combine($pathFromEnv, 'php.exe')
                If (Test-Path -Path $executablePath -PathType Leaf) {
                    $executablePath = [System.IO.Path]::GetFullPath($executablePath)
                    $key = $executablePath.ToLowerInvariant()
                    If (-Not($donePaths.ContainsKey($key))) {
                        $donePaths[$key] = $true
                        $result += Get-PhpVersionFromPath -Path $executablePath
                    }
                }
            }
        }
    }
    End {
        $result
    }
}
