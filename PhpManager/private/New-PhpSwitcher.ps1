function New-PhpSwitcher
{
    <#
    .Synopsis
    Creates a new instance of PhpSwitcher

    .Outputs
    psobject
    #>
    [OutputType([psobject])]
    param (
        [ValidateNotNull()]
        [hashtable]$Data
    )
    begin {
        $result = $null
    }
    process {
        $result = [PhpSwitcher]::new()
        $result.Scope = $Data.scope
        $result.Alias = $Data.alias
        $result.Targets = $Data.targets
    }
    end {
        $result
    }
}
