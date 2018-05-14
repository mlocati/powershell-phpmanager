class PhpExtension
{
    <#
    The type of the PHP extension
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Type
    <#
    The state of the PHP extension
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $State
    <#
    The name of the PHP extension
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Name
    <#
    The handle of the PHP extension
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Handle
    <#
    The version of the PHP extension (empty string if not available)
    #>
    [string]
    [ValidateNotNull()]
    $Version
    <#
    The full path to the extension file (empty string if not available)
    #>
    [string]
    [ValidateNotNull()]
    $Filename
    <#
    Initialize the instance.
    Keys for $data:
    - Type: required
    - State: required
    - Name: required
    - Handle: required
    - Version: optional
    - Filename: optional
    #>
    hidden PhpExtension([hashtable] $data)
    {
        $this.Type = $data.Type
        $this.State = $data.State
        $this.Name = $data.Name
        $this.Handle = $data.Handle
        $this.Version = ''
        if ($data.ContainsKey('Version') -and $null -ne $data.Version) {
            $this.Version = $data.Version
        }
        $this.Filename = ''
        if ($data.ContainsKey('Filename') -and $null -ne $data.Filename) {
            $this.Filename = $data.Filename
        }
    }
}
