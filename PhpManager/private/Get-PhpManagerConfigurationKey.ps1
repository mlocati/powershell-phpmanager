function Get-PhpManagerConfigurationKey
{
    <#
    .Synopsis
    Gets a persisted PhpManager configuration key.

    .Parameter Key
    The key of the configuration to be fetched.
    #>
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Any', 'CurrentUser', 'AllUsers')]
        [string]$Scope = 'Any'
    )
    begin {
        $result = $null
    }
    process {
        if ($Scope -eq 'CurrentUser') {
            $folders = @($Env:LOCALAPPDATA)
        } elseif ($Scope -eq 'AllUsers') {
            $folders = @($Env:ProgramData)
        } else {
            $folders = @($Env:LOCALAPPDATA, $Env:ProgramData)
        }
        foreach ($folder in $folders) {
            if ($folder) {
                $path = Join-Path -Path $folder -ChildPath 'phpmanager.json'
                if (Test-Path -PathType Leaf -LiteralPath $path) {
                    $content = @(Get-Content -LiteralPath $path) -join "`n"
                    $json = ConvertFrom-Json -InputObject $content
                    if ($json.PSobject.Properties.name -eq $Key) {
                        $result = $json.$Key
                        if ($null -ne $result) {
                            break
                        }
                    }
                }
            }
        }
    }
    end {
        $result
    }
}
