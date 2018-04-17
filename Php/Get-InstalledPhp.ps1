function Get-InstalledPhp() {
    <#
    .Synopsis
    Get the details about installed PHP versions

    .Description
    Get the details a PHP version installed in a specific location, or in all the PHP installations found in the current environment PATH.

    .Parameter Path
    Get the details about PHP installed in this location.
    If omitted we'll look for PHP installed in the current PATH.
    #>
    <#

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
            $Path = [System.IO.Path]::GetFullPath($Path)
            If (Test-Path -Path $Path - PathType Lead) {
                $result += Get-PhpVersionFromExecutable -ExecutablePath $Path
            } ElseIf (Test-Path -Path $Path -PathType Container) {
                $executablePath = [System.IO.Path]::Combine($Path, 'php.exe')
                If (-Not(Test-Path -Path $executablePath -PathType Leaf)) {
                    throw "$Path does not contain the PHP executable"
                }
                $result += Get-PhpVersionFromExecutable -ExecutablePath $executablePath
            } else {
                throw "Unable to find the directory/file $Path"
            }
        } Else {
            ForEach ($pathFromEnv in @($env:path.split(';'))) {
                $executablePath = [System.IO.Path]::Combine($pathFromEnv, 'php.exe')
                If (Test-Path -Path $executablePath -PathType Leaf) {
                    $result += Get-PhpVersionFromExecutable -ExecutablePath $executablePath
                }
            }
        }
    }
    End {
        $result
    }
}