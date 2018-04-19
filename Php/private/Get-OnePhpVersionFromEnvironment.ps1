function Get-OnePhpVersionFromEnvironment() {
    <#
    .Synopsis
    Gets one (and only one) PhpVersion instance parsing the the current environment PATH variable.

    .Outputs
    PSObject
    #>
    Param(
    )
    Begin {
        $result = $null
    }
    Process {
        $phpVersionsInPath = @(Get-Php)
        If ($phpVersionsInPath.Count -eq 0) {
            Throw "No PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        If ($phpVersionsInPath.Count -gt 1) {
            Throw "Multiple PHP versions found in the current PATHs: use the -Path argument to specify the location of installed PHP"
        }
        $result = $phpVersionsInPath[0]
    }
    End {
        $result
    }
}
