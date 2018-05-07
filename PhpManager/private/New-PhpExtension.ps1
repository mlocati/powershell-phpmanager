function New-PhpExtension
{
    <#
    .Synopsis
    Creates a new object representing a PHP extension.

    .Parameter Dictionary
    The dictionary with the extension properties.

    .Outputs
    PSCustomObject

    .Example
    New-PhpExtensionState @{
        'Type' = $Script:EXTENSIONSTATE_BUILTIN
        'State' = $Script:EXTENSIONSTATE_BUILTIN
        'Name' = 'Xdebug'
        'Handle' = 'xdebug'
        'Version' = '1.1'
        'Filename' = 'php_xdebug-2.6.0-7.2-vc15.dll'
    }
    #>
    param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The dictionary with the property values')]
        [ValidateNotNull()]
        [Hashtable]$Dictionary
    )
    begin {
        $result = New-Object PSObject
    }
    process {
        $result | Add-Member -MemberType NoteProperty -Name 'Type' -Value ([string]$Dictionary['Type'])
        $result | Add-Member -MemberType NoteProperty -Name 'State' -Value ([string]$Dictionary['State'])
        $result | Add-Member -MemberType NoteProperty -Name 'Name' -Value ([string]$Dictionary['Name'])
        $result | Add-Member -MemberType NoteProperty -Name 'Handle' -Value ([string]$Dictionary['Handle'])
        $result | Add-Member -MemberType NoteProperty -Name 'Version' -Value $( if ($Dictionary.ContainsKey('Version')) { [string]$Dictionary['Version'] } else { '' } )
        $result | Add-Member -MemberType NoteProperty -Name 'Filename' -Value $( if ($Dictionary.ContainsKey('Filename')) { [string]$Dictionary['Filename'] } else { '' } )
    }
    end {
        $result
    }
}
