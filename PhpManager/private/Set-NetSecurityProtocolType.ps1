function Set-NetSecurityProtocolType
{
    <#
    .Synopsis
    Configure the SecurityProtocol of the Net.ServicePointManager.
    #>
    [OutputType()]
    param (
    )
    begin {
    }
    process {
        $regValueName = 'SchUseStrongCrypto'
        try {
            $netVersion = [System.Environment].Assembly.ImageRuntimeVersion
            $regKeyPath = "HKLM:\SOFTWARE\Microsoft\.NETFramework\$netVersion"
            if (Test-Path -LiteralPath $regKeyPath) {
                $regKey = Get-Item -LiteralPath $regKeyPath
                if (-Not($regKey.GetValue($regValueName))) {
                    Write-Verbose "Setting the $regValueName registry key"
                    Set-ItemProperty -LiteralPath $regKeyPath -Name $regValueName -Value 1
                }
                $regKeyPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\$netVersion"
                if (Test-Path -LiteralPath $regKeyPath) {
                    $regKey = Get-Item -LiteralPath $regKeyPath
                    if (-Not($regKey.GetValue($regValueName))) {
                        Write-Verbose "Setting the $regValueName registry key for WOW64"
                        Set-ItemProperty -LiteralPath $regKeyPath -Name $regValueName -Value 1
                    }
                }
            } else {
                Write-Verbose "Failed to find the registry entry for the .NET Runtime version $netVersion"
            }
        } catch [System.Exception] {
            Write-Verbose ("Error while configuring the {0} registry key: {1}" -f $regValueName,$_.Exception.Message)
        }
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
        } catch {
            Write-Verbose '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
        }
    }
    end {
    }
}
