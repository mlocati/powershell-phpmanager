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
    The PHP version for which this extension is designed for
    #>
    [string]
    [ValidateNotNull()]
    $PhpVersion

    <#
    The OS architecture (x86 or x64)
    #>
    [string]
    [ValidateNotNull()]
    $Architecture

    <#
    Is this a thread-safe extension?
    #>
    [Nullable[bool]]
    $ThreadSafe

    <#
    The full path to the extension file (empty string if not available)
    #>
    [string]
    [ValidateNotNull()]
    $Filename

    <#
    Is this a thread-safe extension?
    #>
    [Nullable[int]]
    $ApiVersion

    <#
    Initialize the instance.
    Keys for $data:
    - Type: required
    - State: required
    - Name: required
    - Handle: required
    - PhpVersion: required
    - Architecture: required
    - ThreadSafe: optional
    - ApiVersion: optional
    - Version: optional
    - Filename: optional
    #>
    hidden PhpExtension([hashtable] $data)
    {
        $this.Type = $data.Type
        $this.State = $data.State
        $this.Name = $data.Name
        $this.Handle = $data.Handle
        $this.PhpVersion = $data.PhpVersion
        $this.Architecture = $data.Architecture
        $this.ThreadSafe = $null
        if ($data.ContainsKey('ThreadSafe') -and $null -ne $data.ThreadSafe -and $data.ThreadSafe -ne '') {
            if ($data.ThreadSafe -eq 0 -or $data.ThreadSafe -eq $false) {
                $this.ThreadSafe = $false
            } elseif ($data.ThreadSafe -eq 1 -or $data.ThreadSafe -eq $true) {
                $this.ThreadSafe = $true
            } else {
                throw 'Invalid ThreadSafe value!'
            }
        }
        $this.Version = ''
        if ($data.ContainsKey('Version') -and $null -ne $data.Version) {
            $this.Version = $data.Version
        }
        $this.Filename = ''
        if ($data.ContainsKey('Filename') -and $null -ne $data.Filename) {
            $this.Filename = $data.Filename
        }
        if ($data.ContainsKey('ApiVersion') -and $data.ApiVersion) {
            $this.ApiVersion = [int]$data.ApiVersion
        }
    }
}
