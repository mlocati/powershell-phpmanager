Function Switch-Php
{
    <#
    .Synopsis
    Initializes the PHP Switcher.

    .Parameter Name
    The symbolic name of the PHP installation to activate.

    .Parameter Force
    Force the creation of a PHP Switcher even if there are other PHP installations available in the current path.

    .Example
    Initialize-PhpSwitcher C:\PHP
    Add-PhpToSwitcher 5.6 C:\PHP5.6
    Add-PhpToSwitcher 7.2 C:\PHP7.2
    Switch-Php 5.6
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The symbolic name of the PHP installation to activate')]
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
        If ($switcher.Targets.Count -eq 0) {
            Throw 'PHP Switcher does not contain any PHP installation: you can add PHP installation with the Add-PhpToSwitcher command'
        }
        If (-Not($switcher.Targets.Contains($Name))) {
            Throw ("PHP Switcher does not contain a PHP installation with the symbolic name ""$Name"".`nThe available names are:`n- " + ($switcher.Targets.Keys -join "`n -"))
        }
        $aliasItem = $null
        If (Test-Path -LiteralPath $switcher.Alias -PathType Container) {
            $aliasItem = Get-Item -LiteralPath $switcher.Alias
            If ($aliasItem.LinkType -ne 'Junction') {
                Throw ($switcher.Alias + ' already exist and it''s not a junction.')
            }
        } ElseIf (Test-Path -LiteralPath $switcher.Alias) {
            Throw ($switcher.Alias + ' already exist and it''s not a junction.')
        }
        $target = $switcher.Targets[$Name]
        If (-Not(Test-Path -LiteralPath $target -PathType Container)) {
            Throw "$Name points to $target, which is not a directory"
        }
        $targetItem =  Get-Item -LiteralPath $target
        If ($targetItem.LinkType -eq 'Junction') {
            Throw "$Name points to $target, which is a junction"
        }
        $dsc = [System.IO.Path]::DirectorySeparatorChar
        If (-Not($Force)) {
            $extraPhpInPaths = @()
            ForEach ($phpVersion in @(Get-Php)) {
                $folder = [System.IO.Path]::GetDirectoryName($phpVersion.ExecutablePath).TrimEnd($dsc)
                If ($folder -ne $switcher.Alias.TrimEnd($dsc)) {
                    $extraPhpInPaths += $folder
                }
            }
            If ($extraPhpInPaths.Count -gt 0) {
                Throw ("PHP is currently available in the following directories:`n- " + ($extraPhpInPaths -join "`n -") + "`nPHP Switcher is meant to have PHP in PATH only as " + $switcher.Alias + "`nYou can override this behavior by calling Switch-Php with the -Force flag.")
            }
        }
        If ($null -eq $aliasItem -or $switcher.Alias.TrimEnd($dsc) -ne $target.TrimEnd($dsc)) {
            If ($null -ne $aliasItem) {
                Remove-Item -LiteralPath $switcher.Alias -Recurse -Force
            }
            New-Item -ItemType Junction -Path $switcher.Alias -Value $target | Out-Null
            Edit-PhpFolderInPath -Operation Add -Path $switcher.Alias -Persist $(If ($switcher.Scope -eq 'AllUsers') { 'System' } Else { 'User' } ) -CurrentProcess
        }
    }
    End {
    }
}
