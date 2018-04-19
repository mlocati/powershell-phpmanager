Function Get-PhpAvailableVersions
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
    Get-PhpAvailableVersions -State Release
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
        if (-Not $Reload) {
            $result = Get-Variable -Name $listVariableName -ValueOnly -Scope Script
        }
        if ($result -eq $null) {
            $result = @()
            $urlList = Get-Variable -Name $('URL_LIST_' + $State) -ValueOnly -Scope Script
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
            $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $urlList
            foreach ($link in $webResponse.Links | Where-Object -Property 'Href' -Match ('/' + $Script:RX_ZIPARCHIVE + '$')) {
                $result += Get-PhpVersionFromUrl -Url $link.Href -PageUrl $urlList -ReleaseState $State
            }
            Set-Variable -Scope Script -Name $listVariableName -Value $result -Force
        }
    }
    End {
        $result
    }
}
