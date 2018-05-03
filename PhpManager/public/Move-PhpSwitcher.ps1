Function Move-PhpSwitcher
{
    <#
    .Synopsis
    Changes the path will be visible when switching to a PHP version.

    .Parameter NewAlias
    The path where PHP will be visible when switching to a PHP version.

    .Example
    Move-PhpSwitcher C:\PHP
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The new path where PHP will be visible when switching to a PHP version')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$NewAlias
    )
    Begin {
    }
    Process {
        $switcher = Get-PhpSwitcher
        if ($null -eq $switcher) {
            Throw 'PHP Switcher is not initialized: you can initialize it with the Initialize-PhpSwitcher command'
        }
        $NewAlias = [System.IO.Path]::GetFullPath($NewAlias)
        $newAliasJunction = $null
        If (Test-Path -LiteralPath $NewAlias -PathType Container) {
            $newAliasJunction = Get-Item -LiteralPath $NewAlias
            If ($newAliasJunction.LinkType -ne 'Junction') {
                Throw "$NewAlias already exist and it's not a junction."
            }
        } ElseIf (Test-Path -LiteralPath $NewAlias) {
            Throw "$NewAlias already exist and it's not a junction."
        }
        $oldAlias = $switcher.Alias
        $dsc = [System.IO.Path]::DirectorySeparatorChar
        If ($oldAlias.TrimEnd($dsc) -ne $NewAlias.TrimEnd($dsc)) {
            $recreateAs = $null
            If (Test-Path -LiteralPath $oldAlias -PathType Container) {
                $oldAliasItem = Get-Item -LiteralPath $oldAlias
                If ($oldAliasItem.LinkType -eq 'Junction') {
                    If ($oldAliasItem | Get-Member -Name 'Target') {
                        $s = [string]$oldAliasItem.Target
                        If (Test-Path -LiteralPath $s -PathType Container) {
                            $sItem = Get-Item -LiteralPath $s
                            If (-Not($sItem.LinkType)) {
                                $recreateAs = $s
                            }
                        }
                    }
                    Edit-PhpFolderInPath -Operation Remove -Path $oldAlias
                    Remove-Item -LiteralPath $oldAlias -Recurse -Force
                }
            }
            $switcher.Alias = $NewAlias
            If ($null -ne $recreateAs) {
                If ($null -ne $newAliasJunction) {
                    Remove-Item -LiteralPath $NewAlias -Recurse -Force
                }
                New-Item -ItemType Junction -Path $NewAlias -Value $recreateAs | Out-Null
                Edit-PhpFolderInPath -Operation Add -Path $NewAlias -Persist $(If ($switcher.Scope -eq 'AllUsers') { 'System' } Else { 'User' } ) -CurrentProcess
            }
            Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $switcher -Scope $switcher.Scope
        }
    }
    End {
    }
}
