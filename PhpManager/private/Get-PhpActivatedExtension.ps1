function Get-PhpActivatedExtension
{
    <#
    .Synopsis
    Gets the list of non-builtin extensions enabled in a PHP installation.

    .Parameter PhpVersion
    The instance of PhpVersion for which you want the extensions.

    .Outputs
    System.Array

    .Example
    Get-PhpActivatedExtension -PhpVersion $phpVersion
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
        $builtinExtensions = @(Get-PhpBuiltinExtension -PhpVersion $PhpVersion)
        $executableParameters = @('-m')
        $executableResult = & $PhpVersion.ExecutablePath $executableParameters
        $lines = $executableResult | Where-Object { $_ -notmatch '^\s*$' }
        $alreadyExtensions = @{}
        $type = $null
        foreach ($line in $lines) {
            if ($line -match '\[\s*PHP\s+Modules\s*\]') {
                $type = $Script:EXTENSIONTYPE_PHP
            } elseif ($line -match '\[\s*Zend\s+Modules\s*\]') {
                $type = $Script:EXTENSIONTYPE_ZEND
            } else {
                if ($line -match '^\s*\[.*\]\s*$') {
                    throw "Unrecognized 'php -m' line: $line"
                }
                if ($null -eq $type) {
                    throw "Unexpected 'php -m' line: $line"
                }
                $extensionName = $line -replace '^\s+', '' -replace '\s+$', ''
                $extensionHandle = Get-PhpExtensionHandle -Name $extensionName
                $isBuiltin = $builtinExtensions | Where-Object { $_.Handle -eq $extensionHandle }
                if (-Not($isBuiltin)) {
                    if ($alreadyExtensions.ContainsKey($extensionHandle)) {
                        $alreadyExtensions[$extensionHandle].Type = $type
                    } else {
                        $extension = [PhpExtension]::new(@{
                            'Name' = $extensionName;
                            'Handle' = $extensionHandle;
                            'Type' = $type;
                            'State' = $Script:EXTENSIONSTATE_ENABLED;
                            'PhpVersion' = '' + $PhpVersion.ComparableVersion.Major + '.' + $PhpVersion.ComparableVersion.Minor;
                            'Architecture' = $PhpVersion.Architecture;
                            'ThreadSafe' = $PhpVersion.ThreadSafe;
                        })
                        $alreadyExtensions[$extensionHandle] = $extension
                        $extensions += $extension
                    }
                }
            }
        }
    }
    end {
        $extensions
    }
}
