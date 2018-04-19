Function Get-PhpBuiltinExtensions
{
    <#
    .Synopsis
    Gets the list of extensions builtin in a PHP installation.

    .Parameter PhpVersion
    The instance of PhpVersion for which you want the extensions.

    .Outputs
    System.Array
    
    .Example
    Get-PhpBuiltinExtensions -PhpVersion $phpVersion
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want the extensions')]
        [ValidateNotNull()]
        [PSObject]$PhpVersion
    )
    Begin {
        $extensions = @()
    }
    Process {
        $executableParameters = @('-n', '-m')
        $executableResult = & $PhpVersion.ExecutablePath $executableParameters
        $extensionNames = $executableResult | Where-Object {$_ -notmatch '^\s*\[.*\]\s*$'} | Where-Object {$_ -notmatch '^\s*$'}
        $alreadyExtensions = @{}
        ForEach ($extensionName in $extensionNames) {
            $extensionHandle = Get-PhpExtensionHandle -Name $extensionName
            If (-Not($alreadyExtensions.ContainsKey($extensionHandle))) {
                $alreadyExtensions[$extensionHandle] = $true
                $extensions += New-PhpExtension -Dictionary @{'Name' = $extensionName; 'Handle' = $extensionHandle; 'Type' = $Script:EXTENSIONTYPE_BUILTIN; 'State' = $Script:EXTENSIONSTATE_BUILTIN}
            }
        }
    }
    End {
        $extensions
    }
}
