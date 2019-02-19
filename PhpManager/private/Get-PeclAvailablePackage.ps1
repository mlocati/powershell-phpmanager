function Get-PeclAvailablePackage
{
    <#
    .Synopsis
    Gets the list of available PECL packages.

    .Parameter Reload
    Force the reload of the list.

    .Outputs
    System.Array
    #>
    [OutputType([string[]])]
    param (
        [switch]$Reload
    )
    begin {
        $result = $null
    }
    process {
        if (-Not $Reload) {
            $result = $Script:PECL_PACKAGES
        }
        if ($null -eq $result) {
            Set-NetSecurityProtocolType
            # https://pear.php.net/manual/en/core.rest.php
            $xmlDocument = Invoke-RestMethod -Method Get -Uri ($Script:URL_PECLREST_1_0 + 'p/packages.xml')
            $result = @($xmlDocument | Select-Xml -XPath '/ns:a/ns:p' -Namespace @{'ns' = $xmlDocument.DocumentElement.NamespaceURI} | Select-Object -ExpandProperty Node | Select-Object -ExpandProperty InnerText)
            Set-Variable -Scope Script -Name 'PECL_PACKAGES' -Value $result -Force
        }
    }
    end {
        $result
    }
}
