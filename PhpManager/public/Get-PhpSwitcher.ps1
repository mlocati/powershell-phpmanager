function Get-PhpSwitcher
{
    <#
    .Synopsis
    Gets the currently configured PHP Switcher (if any).

    .Outputs
    psobject|$null
    #>
    [OutputType([psobject])]
    param (
    )
    begin {
        $result = $null
    }
    process {
        $data = @{}
        $data.scope = 'CurrentUser'
        $definition = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $data.scope
        if ($null -eq $definition) {
            $data.scope = 'AllUsers'
            $definition = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $data.scope
        }
        if ($null -ne $definition) {
            $data.alias = ''
            if ($definition | Get-Member -Name 'Alias') {
                if ($definition.Alias) {
                    $data.alias = [string]$definition.Alias
                }
            }
            if ($data.alias -ne '') {
                $data.targets = @{}
                if ($definition | Get-Member -Name 'Targets') {
                    try {
                        $definition.Targets.PSObject.Properties | ForEach-Object {
                            $data.targets[$_.Name] = [string] $_.Value
                        }
                    } catch {
                        Write-Debug $_.Exception.Message
                    }
                }
                $result = New-PhpSwitcher -Data $data
            }
        }
    }
    end {
        $result
    }
}
