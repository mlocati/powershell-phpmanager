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
        [string]$Key,
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateSet('Any', 'CurrentUser', 'AllUsers')]
        [string]$Scope = 'Any'
    )
    Begin {
        $result = $null
    }
    Process {
        If ($Scope -eq 'CurrentUser') {
            $folders = @($Env:LOCALAPPDATA)
        } ElseIf ($Scope -eq 'AllUsers') {
            $folders = @($Env:ProgramData)
        } Else {
            $folders = @($Env:LOCALAPPDATA, $Env:ProgramData)
        }
        ForEach ($folder in $folders) {
            If ($folder) {
                $path = Join-Path -Path $folder -ChildPath 'phpmanager.json'
                If (Test-Path -PathType Leaf -LiteralPath $path) {
                    $content = @(Get-Content -LiteralPath $path) -join ''
                    $json = ConvertFrom-Json -InputObject $content
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
