function Get-PhpBuiltinExtension
{
    <#
    .Synopsis
    Gets the list of extensions builtin in a PHP installation.

    .Parameter PhpVersion
    The instance of PhpVersion for which you want the extensions.

    .Outputs
    System.Array

    .Example
    Get-PhpBuiltinExtension -PhpVersion $phpVersion
    #>
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want the extensions')]
        [ValidateNotNull()]
        [PhpVersionInstalled]$PhpVersion
    )
    begin {
        $extensions = @()
    }
    process {
        $executableParameters = @('-n', '-m')
        $executableResult = & $PhpVersion.ExecutablePath $executableParameters
        $extensionNames = $executableResult | Where-Object { $_ -notmatch '^\s*\[.*\]\s*$' } | Where-Object { $_ -notmatch '^\s*$' }
        $alreadyExtensions = @{}
        foreach ($extensionName in $extensionNames) {
            $extensionHandle = Get-PhpExtensionHandle -Name $extensionName
            if (-Not($alreadyExtensions.ContainsKey($extensionHandle))) {
                $alreadyExtensions[$extensionHandle] = $true
                $extensions += [PhpExtension]::new(@{
                    'Name' = $extensionName;
                    'Handle' = $extensionHandle;
                    'Type' = $Script:EXTENSIONTYPE_BUILTIN;
                    'State' = $Script:EXTENSIONSTATE_BUILTIN;
                    'PhpVersion' = $PhpVersion.FullVersion;
                    'Architecture' = $PhpVersion.Architecture;
                    'ThreadSafe' = $PhpVersion.ThreadSafe;
                })
            }
        }
    }
    end {
        $extensions
    }
}
