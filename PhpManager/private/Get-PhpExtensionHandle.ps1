function Get-PhpExtensionHandle
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
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name of the PHP extension')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Name
    )
    begin {
        $handle = $null
    }
    process {
        $handle = $Name.Trim().ToLowerInvariant()
        if ($handle -eq '') {
            throw 'Empty PHP extension name specified'
        }
        switch ($handle) {
            'zend opcache' { $handle = 'opcache' }
            'advanced php debugger (apd)' { $handle = 'apd' }
            'nt user api' { $handle = 'ntuser' }
            'the ioncube php loader' { $handle = 'ioncube_loader' }
            default {
                $replaced = $handle -replace '\s+', '_'
                if (-Not($replaced -match '^[a-z0-9][a-z0-9_\-]+$')) {
                    throw "Unrecognized PHP extension name: $Name"
                }
                $handle = $replaced
            }
        }
    }
    end {
        $handle
    }
}
