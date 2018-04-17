Function Get-PhpAvailableVersions
{
    <#
    .Synopsis
    Gets the list of available versions.

    .Parameter State
    The release state (can be QA, Release or Archive)

    .Parameter Reload
    Force the reload of the list

    .Outputs
    System.Array
    
    .Example
    Get-PhpAvailableVersions 'Release'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The release state (can be QA, RELEASE or Archive)')]
        [ValidateSet('QA', 'Release', 'Archive')]
        [string]$State,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'Force the reload of the list')]
        [bool]$Reload
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
            Set-Variable -Name $listVariableName -Value $result -Force -Scope Script
        }
    }
    End {
        $result
    }
}
