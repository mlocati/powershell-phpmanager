Function Get-PhpActivatedExtension
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
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want the extensions')]
        [ValidateNotNull()]
        [PSObject]$PhpVersion
    )
    Begin {
        $extensions = @()
    }
    Process {
        $builtinExtensions = Get-PhpBuiltinExtension -PhpVersion $PhpVersion
        $executableParameters = @('-m')
        $executableResult = & $PhpVersion.ExecutablePath $executableParameters
        $lines = $executableResult | Where-Object {$_ -notmatch '^\s*$'}
        $alreadyExtensions = @{}
        $type = $null
        ForEach ($line in $lines) {
            If ($line -match '\[\s*PHP\s+Modules\s*\]') {
                $type = $Script:EXTENSIONTYPE_PHP
            } ElseIf ($line -match '\[\s*Zend\s+Modules\s*\]') {
                $type = $Script:EXTENSIONTYPE_ZEND
            } Else {
                If ($line -match '^\s*\[.*\]\s*$') {
                    throw "Unrecognized 'php -m' line: $line"
                }
                If ($null -eq  $type) {
                    throw "Unexpected 'php -m' line: $line"
                }
                $extensionName = $line -replace '^\s+', '' -replace '\s+$', ''
                $extensionHandle = Get-PhpExtensionHandle -Name $extensionName
                $isBuiltin = $builtinExtensions | Where-Object { $_.Handle -eq $extensionHandle}
                If (-Not($isBuiltin)) {
                    If ($alreadyExtensions.ContainsKey($extensionHandle)) {
                        $alreadyExtensions[$extensionHandle].Type = $type
                    } else {
                        $extension = New-PhpExtension -Dictionary @{'Name' = $extensionName; 'Handle' = $extensionHandle; 'Type' = $type; 'State' = $Script:EXTENSIONSTATE_ENABLED}
                        $alreadyExtensions[$extensionHandle] = $extension
                        $extensions += $extension
                    }
                }
            }
        }
    }
    End {
        $extensions
    }
}
