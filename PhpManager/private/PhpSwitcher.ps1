class PhpSwitcher
{
    <#
    The scope of the PHP Switcher.
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    $Scope
    <#
    The target directory where PHP will be visible.
    #>
    [string]
    [ValidateNotNull()]
    [ValidateLength(1, [int]::MaxValue)]
    $Alias
    <#
    All the PHP installations associated to this PHP Switcher.
    #>
    [hashtable]
    [ValidateNotNull()]
    $Targets
    <#
    Initialize the instance.
    Keys for $data:
    - scope: required
    - alias: required
    - targets: required
    #>
    hidden PhpSwitcher([hashtable] $data)
    {
        $this.Scope = $data.scope
        $this.Alias = $data.alias
        $this.Targets = $data.targets
    }
}
