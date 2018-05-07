function Get-PhpSwitcher
{
    <#
    .Synopsis
    Gets the currently configured PHP Switcher (if configured).

    .Outputs
    PSCustomObject|$null
    #>
    begin {
        $result = $null
    }
    process {
        $scope = 'CurrentUser'
        $data = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $scope
        if ($null -eq $data) {
            $scope = 'AllUsers'
            $data = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $scope
        }
        if ($null -ne $data) {
            $result = New-Object PSObject
            $result | Add-Member -MemberType NoteProperty -Name 'Scope' -Value $scope
            $alias = ''
            if ($data | Get-Member -Name 'Alias') {
                if ($data.Alias) {
                    $alias = [string]$data.Alias
                }
            }
            $result | Add-Member -MemberType NoteProperty -Name 'Alias' -Value $alias
            $targets = @{}
            if ($data | Get-Member -Name 'Targets') {
                try {
                    $data.Targets.PSObject.Properties | ForEach-Object {
                        $targets[$_.Name] = [string] $_.Value
                    }
                } catch {
                    Write-Debug $_.Exception.Message
                }
            }
            $result | Add-Member -MemberType NoteProperty -Name 'Targets' -Value $targets
        }
    }
    end {
        $result
    }
}
