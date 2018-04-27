Function Get-PhpExtensionHandle
{
    <#
    .Synopsis
    Gets the handle of a PHP extension given its name.

    .Parameter Name
    The name of the PHP extension.

    .Outputs
    string

    .Example
    Get-PhpExtensionHandle -Name 'Zend OPcache'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The name of the PHP extension')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Name
    )
    Begin {
        $handle = $null
    }
    Process {
        $handle = $Name.Trim().ToLowerInvariant()
        If ($handle -eq '') {
            Throw 'Empty PHP extension name specified'
        }
        Switch ($handle) {
            'zend opcache' { $handle = 'opcache' }
            'advanced php debugger (apd)' { $handle = 'apd' }
            'nt user api' { $handle = 'ntuser' }
            default {
                If (-Not($handle -match '^[a-z0-9][a-z0-9_\-]+$')) {
                    Throw "Unrecognized PHP extension name: $Name"
                }
            }
        }
    }
    End {
        $handle
    }
}
