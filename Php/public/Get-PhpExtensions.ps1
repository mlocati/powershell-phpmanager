function Get-PhpExtensions() {
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
    Param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path to the PHP installation (or the path to the php.exe file); if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    Begin {
        $result = @()
    }
    Process {
        If ($Path -eq $null -or $Path -eq '') {
            $phpVersion = Get-OnePhpVersionFromEnvironment
        } Else {
            If (-Not(Test-Path -Path $Path)) {
                throw "Unable to find the directory/file $Path"
            }
            $phpVersion = Get-PhpVersionFromPath -Path $Path
        }
        $result += Get-PhpBuiltinExtensions -PhpVersion $phpVersion
        $dllExtensions = Get-PhpExtensionDetail -PhpVersion $phpVersion
        $activatedExtensions = Get-PhpActivatedExtensions -PhpVersion $phpVersion
        ForEach ($dllExtension in $dllExtensions) {
            If ($activatedExtensions | Where-Object {$_.Handle -eq $dllExtension.Handle}) {
                $dllExtension.State = $Script:EXTENSIONSTATE_ENABLED
            } Else {
                $dllExtension.State = $Script:EXTENSIONSTATE_DISABLED
            }
            $result += $dllExtension
        }
    }
    End {
        $result
    }
}
