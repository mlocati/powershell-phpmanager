function Set-PhpManagerConfigurationKey
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
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $false, Position = 1)]
        $Value,
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet('CurrentUser', 'AllUsers')]
        $Scope
    )
    begin {
        if ($Scope -eq 'AllUsers') {
            $folder = $Env:ProgramData
            if (-Not(Test-Path -PathType Container -LiteralPath $folder)) {
                throw "Unable to find the ProgramData folder ($folder)"
            }
        } else {
            $folder = $Env:LOCALAPPDATA
            if (-Not(Test-Path -PathType Container -LiteralPath $folder)) {
                throw "Unable to find the LocalAppData folder ($folder)"
            }
        }
        $path = Join-Path -Path $folder -ChildPath 'phpmanager.json'
        $json = $null
        if (Test-Path -PathType Leaf -LiteralPath $path) {
            $content = @(Get-Content -LiteralPath $path) -join "`n"
            $json = ConvertFrom-Json -InputObject $content
        }
        if (-Not($json)) {
            $json = New-Object -TypeName PSCustomObject
        }
    }
    process {
        if ($null -eq $Value) {
            $json.PSObject.Properties.Remove($Key)
        } else {
            $json | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        }
    }
    end {
        $props = @($json | Get-Member -MemberType Property,NoteProperty)
        if ($props.Count -eq 0) {
            if (Test-Path -PathType Leaf -LiteralPath $path) {
                Remove-Item -LiteralPath $path
            }
        } else {
            ConvertTo-Json -InputObject $json | Set-Content -LiteralPath $path
        }
        if ($Scope -eq 'AllUsers') {
            Set-PhpManagerConfigurationKey -Key $Key -Value $null -Scope CurrentUser
        }
    }
}
