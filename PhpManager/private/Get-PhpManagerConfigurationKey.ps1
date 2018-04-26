Function Get-PhpManagerConfigurationKey
{
    <#
    .Synopsis
    Gets a persisted PhpManager configuration key.

    .Parameter Key
    The key of the configuration to be fetched.
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key
    )
    Begin {
        $result = $null
    }
    Process {
        $folders = @($Env:LOCALAPPDATA, $Env:ProgramData)
        ForEach ($folder in $folders) {
            If ($folder) {
                $path = Join-Path -Path $folder -ChildPath 'phpmanager.json'
                If (Test-Path -PathType Leaf -LiteralPath $path) {
                    $json = Get-Content -LiteralPath $path | ConvertFrom-Json
                    If ($json.PSobject.Properties.name -eq $Key) {
                        $result = $json.$Key
                        If ($null -ne $result) {
                            Break
                        }
                    }
                }
            }
        }
    }
    End {
        $result
    }
}
