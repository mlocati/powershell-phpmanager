Function Set-PhpManagerConfigurationKey
{
    <#
    .Synopsis
    Persist a PhpManager configuration key.

    .Parameter Key
    The key of the configuration to be saved.

    .Parameter Value
    The value of the configuration to be saved.

    .Parameter Scope
    Persist the value for 'CurrentUser' or for 'AllUsers'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $false, Position = 1)]
        $Value,
        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        $Scope
    )
    Begin {
        If ($Scope -eq 'AllUsers') {
            $folder = $Env:ProgramData
            If (-Not(Test-Path -PathType Container -LiteralPath $folder)) {
                Throw "Unable to find the ProgramData folder ($folder)"
            }
        } Else {
            $folder = $Env:LOCALAPPDATA
            If (-Not(Test-Path -PathType Container -LiteralPath $folder)) {
                Throw "Unable to find the LocalAppData folder ($folder)"
            }
        }
        $path = Join-Path -Path $folder -ChildPath 'phpmanager.json'
        $json = $null
        If (Test-Path -PathType Leaf -LiteralPath $path) {
            $json = Get-Content -LiteralPath $path | ConvertFrom-Json
        }
        If (-Not($json)) {
            $json = New-Object -TypeName PSCustomObject
        }
    }
    Process {
        If ($null -eq $Value) {
            $json.PSObject.Properties.Remove($key)
        } Else {
            $json | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        }
    }
    End {
        $props = @($json | Get-Member -MemberType Property,NoteProperty)
        If ($props.Count -eq 0) {
            If (Test-Path -PathType Leaf -LiteralPath $path) {
                Remove-Item -LiteralPath $path
            }
        } Else {
            ConvertTo-Json -InputObject $json | Set-Content -LiteralPath $path
        }
        If ($Scope -eq 'AllUsers') {
            Set-PhpManagerConfigurationKey -Key $Key -Value $null -Scope CurrentUser
        }
    }
}
