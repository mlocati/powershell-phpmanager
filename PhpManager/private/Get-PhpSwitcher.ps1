Function Get-PhpSwitcher
{
    <#
    .Synopsis
    Gets the currently configured PHP Switcher (if configured).

    .Outputs
    PSCustomObject|$null
    #>
    Begin {
        $result = $null
    }
    Process {
        $scope = 'CurrentUser'
        $data = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $scope
        If ($data -eq $null) {
            $scope = 'AllUsers'
            $data = Get-PhpManagerConfigurationKey -Key 'PHP_SWITCHER' -Scope $scope
        }
        If ($data -ne $null) {
            $result = New-Object PSObject
            $result | Add-Member -MemberType NoteProperty -Name 'Scope' -Value $scope
            $alias = ''
            If ($data | Get-Member -Name 'Alias') {
                If ($data.Alias) {
                    $alias = [string]$data.Alias
                }
            }
            $result | Add-Member -MemberType NoteProperty -Name 'Alias' -Value $alias
            $targets = @{}
            If ($data | Get-Member -Name 'Targets') {
                Try {
                    $data.Targets.PSObject.Properties | ForEach-Object {
                        $targets[$_.Name] = [string] $_.Value
                    }
                }
                Catch {
                    Write-Debug $_.Exception.Message
                }
            }
            $result | Add-Member -MemberType NoteProperty -Name 'Targets' -Value $targets
        }
    }
    End {
        $result
    }
}
