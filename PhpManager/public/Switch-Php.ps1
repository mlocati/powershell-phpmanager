function Switch-Php
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
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The symbolic name of the PHP installation to activate')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Name,
        [switch]$Force
    )
    begin {

    }
    process {
        $switcher = Get-PhpSwitcher
        if ($null -eq $switcher) {
            throw 'PHP Switcher is not initialized: you can initialize it with the Initialize-PhpSwitcher command'
        }
        if ($switcher.Targets.Count -eq 0) {
            throw 'PHP Switcher does not contain any PHP installation: you can add PHP installation with the Add-PhpToSwitcher command'
        }
        if (-Not($switcher.Targets.Contains($Name))) {
            throw ("PHP Switcher does not contain a PHP installation with the symbolic name ""$Name"".`nThe available names are:`n- " + ($switcher.Targets.Keys -join "`n -"))
        }
        $aliasItem = $null
        if (Test-Path -LiteralPath $switcher.Alias -PathType Container) {
            $aliasItem = Get-Item -LiteralPath $switcher.Alias
            if ($aliasItem.LinkType -ne 'Junction') {
                throw ($switcher.Alias + ' already exist and it''s not a junction.')
            }
        } elseif (Test-Path -LiteralPath $switcher.Alias) {
            throw ($switcher.Alias + ' already exist and it''s not a junction.')
        }
        $target = $switcher.Targets[$Name]
        if (-Not(Test-Path -LiteralPath $target -PathType Container)) {
            throw "$Name points to $target, which is not a directory"
        }
        $targetItem = Get-Item -LiteralPath $target
        if ($targetItem.LinkType -eq 'Junction') {
            throw "$Name points to $target, which is a junction"
        }
        $dsc = [System.IO.Path]::DirectorySeparatorChar
        if (-Not($Force)) {
            $extraPhpInPaths = @()
            foreach ($phpVersion in @([PhpVersionInstalled]::FromEnvironment())) {
                $folder = $phpVersion.Folder
                if ($folder -ne $switcher.Alias.TrimEnd($dsc)) {
                    $extraPhpInPaths += $folder
                }
            }
            if ($extraPhpInPaths.Count -gt 0) {
                throw ("PHP is currently available in the following directories:`n- " + ($extraPhpInPaths -join "`n -") + "`nPHP Switcher is meant to have PHP in PATH only as " + $switcher.Alias + "`nYou can override this behavior by calling Switch-Php with the -Force flag.")
            }
        }
        if ($null -eq $aliasItem -or $switcher.Alias.TrimEnd($dsc) -ne $target.TrimEnd($dsc)) {
            if ($null -ne $aliasItem) {
                Remove-Item -LiteralPath $switcher.Alias -Recurse -Force
            }
            New-Item -ItemType Junction -Path $switcher.Alias -Value $target | Out-Null
            Edit-FolderInPath -Operation Add -Path $switcher.Alias -Persist $(if ($switcher.Scope -eq 'AllUsers') { 'System' } else { 'User' } ) -CurrentProcess
        }
    }
    end {
    }
}
