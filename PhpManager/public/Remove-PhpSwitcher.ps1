function Remove-PhpSwitcher
{
    begin {
    }
    process {
        $switcher = Get-PhpSwitcher
        if ($null -ne $switcher) {
            Edit-PhpFolderInPath -Operation Remove -Path $switcher.Alias
            if (Test-Path -LiteralPath $switcher.Alias -PathType Container) {
                $aliasItem = Get-Item -LiteralPath $switcher.Alias
                if ($aliasItem.LinkType -eq 'Junction') {
                    Remove-Item -LiteralPath $switcher.Alias -Force -Recurse
                }
            }
            Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $null -Scope $switcher.Scope
            Write-Output ('The PHP Switcher has been deleted (scope: ' + $switcher.Scope + ').')
        } else {
            Write-Output 'No PHP Switcher is defined.'
        }
    }
    end {
    }
}
