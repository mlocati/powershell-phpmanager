Function Add-PhpToSwitcher
{
    <#
    .Synopsis
    Adds a PHP installation to the PHP Switcher.

    .Parameter Name
    The symbolic name to give to the PHP installation.

    .Parameter Path
    The path to an existing PHP installation to be added to the PHP Switcher.

    .Parameter Force
    Force adding the PHP installation to the PHP Switcher even if another installation is already defined with the specified name.

    .Example
    Initialize-PhpSwitcher C:\PHP
    Add-PhpToSwitcher 5.6 C:\PHP5.6
    Add-PhpToSwitcher 7.2 C:\PHP7.2
    Switch-Php 5.6
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The symbolic name to give to the PHP installation')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Name,
        [Parameter(Mandatory = $True, Position = 1, HelpMessage = 'The path to an existing PHP installation to be added to the PHP Switcher')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [switch]$Force
    )
    Begin {
    }
    Process {
        $switcher = Get-PhpSwitcher
        if ($null -eq $switcher) {
            Throw 'PHP Switcher is not initialized: you can initialize it with the Initialize-PhpSwitcher command'
        }
        If ($switcher.Targets.ContainsKey($Name) -and -Not($Force)) {
            Throw "Another PHP installation ($($switcher.Targets[$Name])) is already assigned to the PHP Switcher with the name $Name. Use the -Force flag to force the operation anyway."
        }
        $Path = [System.IO.Path]::GetFullPath($Path)
        If (-Not(Test-Path -LiteralPath $Path -PathType Container)) {
            Throw "Unable to find the folder $Path"
        }
        $pathInfo = Get-Item -LiteralPath $Path
        If ($pathInfo.LinkType -eq 'Junction') {
            Throw "$Path must be a regular directory (it is a junction)."
        }
        [PhpVersionInstalled]::FromPath($Path) | Out-Null
        $switcher.Targets[$Name] = $Path
        Set-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Value $switcher -Scope $switcher.Scope
    }
    End {
    }
}
