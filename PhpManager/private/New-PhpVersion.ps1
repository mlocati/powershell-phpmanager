Function New-PhpVersion
{
    <#
    .Synopsis
    Creates a new object representing a PHP version.

    .Description
    This function creates a new object containing the details about a PHP version.

    .Parameter Dictionary
    The dictionary with the property values.

    .Outputs
    PSCustomObject
    
    .Example
    New-PhpVersion @{
        'BaseVersion' = '7.1.2';
        'RC' = 1;
        'Architecture' = $Script:ARCHITECTURE_64BITS;
        'ThreadSafe' = true;
        'VCVersion' = 15;
        'ReleaseState' = $Script:RELEASESTATE_RELEASE;
        'DownloadUrl' = 'http://www.example.com';
        'ExecutablePath' = 'C:\Dev\PHP\php.exe'
        'IniPath' => 'C:\Dev\PHP\php.ini'
        'ExtensionsPath' => 'C:\Dev\PHP\ext'
    }
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The dictionary with the property values')]
        [ValidateNotNull()]
        [Hashtable]$Dictionary
    )
    Begin {
        $result = New-Object PSObject
    }
    Process {
        $result | Add-Member -MemberType NoteProperty -Name 'BaseVersion' -Value ([string]$Dictionary['BaseVersion'])
        $result | Add-Member -MemberType NoteProperty -Name 'RC' -Value $( If ($Dictionary.ContainsKey('RC')) { [string]$Dictionary['RC'] } Else { '' } )
        $fullVersion = $result.BaseVersion
        $comparableVersion = $result.BaseVersion
        If ($result.RC -eq '') {
            $comparableVersion += '.9999'
        } else {
            $fullVersion += 'RC' + $result.RC
            $comparableVersion += '.' + $result.RC
        }
        $result | Add-Member -MemberType NoteProperty -Name 'FullVersion' -Value $fullVersion
        $result | Add-Member -MemberType NoteProperty -Name 'ComparableVersion' -Value $([System.Version]$comparableVersion
        $result | Add-Member -MemberType NoteProperty -Name 'Architecture' -Value $([string]$Dictionary['Architecture']))
        $result | Add-Member -MemberType NoteProperty -Name 'ThreadSafe' -Value $([bool]$Dictionary['ThreadSafe'])
        $result | Add-Member -MemberType NoteProperty -Name 'VCVersion' -Value $([int]$Dictionary['VCVersion'])
        If ($Dictionary.ContainsKey('ReleaseState') -and [string]$Dictionary['ReleaseState'] -ne '' -and [string]$Dictionary['ReleaseState'] -ne $Script:RELEASESTATE_UNKNOWN) {
            $result | Add-Member -MemberType NoteProperty -Name 'ReleaseState' -Value $([string]$Dictionary['ReleaseState'])
        }
        If ($Dictionary.ContainsKey('DownloadUrl') -and [string]$Dictionary['DownloadUrl'] -ne '') {
            $result | Add-Member -MemberType NoteProperty -Name 'DownloadUrl' -Value $([string]$Dictionary['DownloadUrl'])
        }
        If ($Dictionary.ContainsKey('ExecutablePath') -and [string]$Dictionary['ExecutablePath'] -ne '') {
            $result | Add-Member -MemberType NoteProperty -Name 'ExecutablePath' -Value $([string]$Dictionary['ExecutablePath'])
        }
        If ($Dictionary.ContainsKey('IniPath') -and [string]$Dictionary['IniPath'] -ne '') {
            $result | Add-Member -MemberType NoteProperty -Name 'IniPath' -Value $([string]$Dictionary['IniPath'])
        }
        If ($Dictionary.ContainsKey('ExtensionsPath') -and [string]$Dictionary['ExtensionsPath'] -ne '') {
            $result | Add-Member -MemberType NoteProperty -Name 'ExtensionsPath' -Value $([string]$Dictionary['ExtensionsPath'])
        }
        $displayName = 'PHP ' + $result.FullVersion + ' ' + $result.Architecture
        if ($result.Architecture -eq $Script:ARCHITECTURE_32BITS) {
            $displayName += ' (32-bit)'
        } elseif ($result.Architecture -eq $Script:ARCHITECTURE_64BITS) {
            $displayName += ' (64-bit)'
        }
        If ($result.ThreadSafe) {
            $displayName += ' Thread-Safe'
        } else {
            $displayName += ' Non-Thread-Safe'
        }
        $result | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $displayName
    }
    End {
        $result
    }
}
