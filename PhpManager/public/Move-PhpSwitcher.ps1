function Move-PhpSwitcher
{
    <#
    .Synopsis
    Changes the path will be visible when switching to a PHP version.

    .Parameter NewAlias
    The path where PHP will be visible when switching to a PHP version.

    .Example
    Move-PhpSwitcher C:\PHP
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The new path where PHP will be visible when switching to a PHP version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$NewAlias
    )
    begin {
    }
    process {
        $switcher = Get-PhpSwitcher
        if ($null -eq $switcher) {
            throw 'PHP Switcher is not initialized: you can initialize it with the Initialize-PhpSwitcher command'
        }
        $NewAlias = [System.IO.Path]::GetFullPath($NewAlias)
        $newAliasJunction = $null
        if (Test-Path -LiteralPath $NewAlias -PathType Container) {
            $newAliasJunction = Get-Item -LiteralPath $NewAlias
            if ($newAliasJunction.LinkType -ne 'Junction') {
                throw "$NewAlias already exist and it's not a junction."
            }
        } elseif (Test-Path -LiteralPath $NewAlias) {
            throw "$NewAlias already exist and it's not a junction."
        }
        $oldAlias = $switcher.Alias
        $dsc = [System.IO.Path]::DirectorySeparatorChar
        if ($oldAlias.TrimEnd($dsc) -ne $NewAlias.TrimEnd($dsc)) {
            $recreateAs = $null
            if (Test-Path -LiteralPath $oldAlias -PathType Container) {
                $oldAliasItem = Get-Item -LiteralPath $oldAlias
                if ($oldAliasItem.LinkType -eq 'Junction') {
                    if ($oldAliasItem | Get-Member -Name 'Target') {
                        $s = [string]$oldAliasItem.Target
                        if (Test-Path -LiteralPath $s -PathType Container) {
                            $sItem = Get-Item -LiteralPath $s
                            if (-Not($sItem.LinkType)) {
                                $recreateAs = $s
                            }
                        }
                    }
                    Edit-FolderInPath -Operation Remove -Path $oldAlias
                    Remove-Item -LiteralPath $oldAlias -Recurse -Force
                }
            }
            $switcher.Alias = $NewAlias
            if ($null -ne $recreateAs) {
                if ($null -ne $newAliasJunction) {
                    Remove-Item -LiteralPath $NewAlias -Recurse -Force
                }
                New-Item -ItemType Junction -Path $NewAlias -Value $recreateAs | Out-Null
                Edit-FolderInPath -Operation Add -Path $NewAlias -Persist $(if ($switcher.Scope -eq 'AllUsers') { 'System' } else { 'User' } ) -CurrentProcess
            }
            Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $switcher -Scope $switcher.Scope
        }
    }
    end {
    }
}
