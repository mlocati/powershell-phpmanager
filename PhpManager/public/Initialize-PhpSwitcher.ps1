function Initialize-PhpSwitcher
{
    <#
    .Synopsis
    Initializes the PHP Switcher.

    .Parameter Alias
    The path where PHP will be visible when switching to a PHP version.

    .Parameter Scope
    Initialize the PHP Switcher for the current user only ('CurrentUser' - default), or for any user ('AllUsers').

    .Parameter Force
    Force the creation of a PHP Switcher even if there's already an existing switcher.

    .Example
    Initialize-PhpSwitcher C:\PHP
    Add-PhpToSwitcher 5.6 C:\PHP5.6
    Add-PhpToSwitcher 7.2 C:\PHP7.2
    Switch-Php 5.6
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The path where PHP will be visible when switching to a PHP version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Alias,
        [Parameter(Mandatory = $false, Position = 99, HelpMessage = 'Initialize the PHP Switcher for the current user only (''CurrentUser''), or for any user (''AllUsers'')')]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',
        [switch]$Force
    )
    begin {
    }
    process {
        $existingSwitcher = Get-PhpSwitcher
        if ($null -ne $existingSwitcher) {
            if ($Scope -eq 'AllUsers' -and $existingSwitcher.Scope -eq 'CurrentUser') {
                throw 'It''s not possible to create a PHP Switcher for all users while there''s a PHP Switcher for the current user.'
            }
            if ($Scope -eq $existingSwitcher.Scope) {
                if (-Not($Force)) {
                    throw 'Another PHP Switcher already exists. You should delete it first (with the Remove-PhpSwitcher command), or use the -Force flag.'
                }
            } else {
                $existingSwitcher = $null
            }
        }
        $newSwitcher = @{}
        $Alias = [System.IO.Path]::GetFullPath($Alias)
        if (Test-Path -LiteralPath $Alias -PathType Container) {
            $aliasItem = Get-Item -LiteralPath $Alias
            if ($aliasItem.LinkType -ne 'Junction') {
                throw "$Alias already exist and it's not a junction."
            }
        } elseif (Test-Path -LiteralPath $Alias) {
            throw "$Alias already exist and it's not a junction."
        }
        $newSwitcher.Alias = $Alias
        $newSwitcher.Targets = @{}
        if ($existingSwitcher) {
            Remove-PhpSwitcher
        }
        Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $newSwitcher -Scope $Scope
        Write-Verbose 'The new PHP Switcher has been created.'
    }
    end {
    }
}
