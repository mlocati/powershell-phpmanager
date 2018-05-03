Function Get-PhpAvailableVersion
{
    <#
    .Synopsis
    Gets the list of available versions.

    .Parameter State
    The release state (can be 'Release', 'Archive' or 'QA').

    .Parameter Reload
    Force the reload of the list.

    .Outputs
    System.Array

    .Example
    Get-PhpAvailableVersion -State Release
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The release state (can be ''Release'' or ''Archive'' or ''QA'')')]
        [ValidateSet('QA', 'Release', 'Archive')]
        [string]$State,
        [Parameter(Mandatory = $False,HelpMessage = 'Force the reload of the list')]
        [switch]$Reload
    )
    Begin {
        $result = $null
    }
    Process {
        $listVariableName = 'AVAILABLEVERSIONS_' + $State
        If (-Not $Reload) {
            $result = Get-Variable -Name $listVariableName -ValueOnly -Scope Script
        }
        If ($null -eq $result) {
            $result = @()
            $urlList = Get-Variable -Name $('URL_LIST_' + $State) -ValueOnly -Scope Script
            Try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
            }
            Catch {
                Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
            }
            $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $urlList
            ForEach ($link In $webResponse.Links | Where-Object -Property 'Href' -Match ('/' + $Script:RX_ZIPARCHIVE + '$')) {
                $result += [PhpVersionDownloadable]::FromUrl($link.Href, $urlList, $State)
            }
            Set-Variable -Scope Script -Name $listVariableName -Value $result -Force
        }
    }
    End {
        $result
    }
}
