Function Remove-PhpFromSwitcher
{
    <#
    .Synopsis
    Removes a PHP installation from the PHP Switcher.

    .Parameter Name
    The symbolic name of the PHP installation to be removed from the PHP Switcher.
    If no symbolic name exists with this name, nothing occurs.

    .Parameter Force
    Force removing the PHP installation from the PHP Switcher even if it is the currently active one.

    .Example
    Initialize-PhpSwitcher C:\PHP
    Add-PhpToSwitcher 5.6 C:\PHP5.6
    Add-PhpToSwitcher 7.2 C:\PHP7.2
    Remove-PhpFromSwitcher 5.6
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The symbolic name of the PHP installation to be removed from the PHP Switcher')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Name,
        [switch]$Force
    )
    Begin {
    }
    Process {
        $switcher = Get-PhpSwitcher
        if ($null -eq $switcher) {
            Throw 'PHP Switcher is not initialized: you can initialize it with the Initialize-PhpSwitcher command'
        }
        If ($switcher.Targets.ContainsKey($Name)) {
            If (-Not($Force)) {
                If (Test-Path -LiteralPath $switcher.Alias -PathType Container) {
                    $aliasItem = Get-Item -LiteralPath $switcher.Alias
                    If ($aliasItem.LinkType -eq 'Junction') {
                        $aliasTarget = [string]$aliasItem.Target
                        $dsc = [System.IO.Path]::DirectorySeparatorChar
                        if ($aliasTarget.TrimEnd($dsc) -eq $switcher.Targets[$Name].TrimEnd($dsc)) {
                            Throw "$Name is the currently active version for the PHP Switcher. Use -Force to remove it anyway."
                        }
                    }
                }
            }
            $switcher.Targets.Remove($Name)
            Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $switcher -Scope $switcher.Scope
        }
    }
    End {
    }
}
