function Get-PhpExtension() {
    <#
    .Synopsis
    Lists the extensions for PHP installation.

    .Description
    Lists all the extensions found in a PHP installation (Builtin, Enabled and Disabled).

    .Parameter Path
    The path to the PHP installation (or the path to the php.exe file).
    If omitted we'll use the one found in the PATH environment variable.

    .Outputs
    System.Array
    #>
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path to the PHP installation (or the path to the php.exe file); if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    begin {
        $result = @()
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $result += Get-PhpBuiltinExtension -PhpVersion $phpVersion
        $dllExtensions = @(Get-PhpExtensionDetail -PhpVersion $phpVersion)
        $activatedExtensions = @(Get-PhpActivatedExtension -PhpVersion $phpVersion)
        foreach ($dllExtension in $dllExtensions) {
            if ($activatedExtensions | Where-Object { $_.Handle -eq $dllExtension.Handle }) {
                $dllExtension.State = $Script:EXTENSIONSTATE_ENABLED
            } else {
                $dllExtension.State = $Script:EXTENSIONSTATE_DISABLED
            }
            $result += $dllExtension
        }
    }
    end {
        $result
    }
}
