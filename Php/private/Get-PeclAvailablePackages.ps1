Function Get-PeclAvailablePackages
{
    <#
    .Synopsis
    Gets the list of available PECL packages.

    .Parameter Reload
    Force the reload of the list.

    .Outputs
    System.Array
    #>
    Param (
        [switch]$Reload
    )
    Begin {
        $result = $null
    }
    Process {
        If (-Not $Reload) {
            $result = $Script:PECL_PACKAGES
        }
        If ($null -eq $result) {
            Try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
            }
            Catch {
                Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
            }
            # https://pear.php.net/manual/en/core.rest.php
            $xmlDocument = Invoke-RestMethod -Method Get -Uri ($Script:URL_PECLREST_1_0 + 'p/packages.xml')
            $result = @($xmlDocument | Select-Xml -XPath '/ns:a/ns:p' -Namespace @{'ns' = $xmlDocument.DocumentElement.NamespaceURI} | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty InnerText)
            Set-Variable -Scope Script -Name 'PECL_PACKAGES' -Value $result -Force
        }
    }
    End {
        $result
    }
}
