Function Remove-PhpSwitcher
{
    Begin {
    }
    Process {
        $switcher = Get-PhpSwitcher
        If ($switcher -ne $null) {
            Remove-PhpFolderFromPath -Path $switcher.Alias
            If (Test-Path -LiteralPath $switcher.Alias -PathType Container) {
                $aliasItem = Get-Item -LiteralPath $switcher.Alias
                If ($aliasItem.LinkType -eq 'Junction') {
                    Remove-Item -LiteralPath $switcher.Alias -Force -Recurse
                }
            }
            Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $null -Scope $switcher.Scope
            Write-Output ('The PHP Switcher has been deleted (scope: ' + $switcher.Scope + ').')
        } Else {
            Write-Output 'No PHP Switcher is defined.'
        }
    }
    End {
    }
}
