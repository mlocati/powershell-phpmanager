function Get-WebResource {
    <#
    .Synopsis
    Call Invoke-WebRequest, repeating it in case of specific errors
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The URL of the resource to be fetched')]
        [ValidateNotNull()]
        [string] $Uri,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'the output file for which this cmdlet saves the response body')]
        [string] $OutFile = '',
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The number of retries in case of specific errors')]
        [ValidateNotNull()]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Retries = 3
    )
    begin {
        Set-NetSecurityProtocolType
        $result = $null
    }
    process {
        if ($null -eq $OutFile) {
            $OutFile = '';
        }
        for ($cycle = 0; $cycle -lt $Retries; $cycle++) {
            try {
                if ($OutFile -eq '') {
                    $result = Invoke-WebRequest -Uri $Uri -UseBasicParsing -Verbose:$false
                } else {
                    $result = Invoke-WebRequest -Uri $Uri -UseBasicParsing -OutFile $OutFile -Verbose:$false
                }
                break
            } catch [System.ComponentModel.Win32Exception] {
                if ($cycle -lt $Retries) {
                    if ($_.ErrorCode -eq 0x80090304) { # The Local Security Authority cannot be contacted
                        Write-Verbose "Downloading from {$Uri} failed with error $($_.Message): retrying..."
                        continue
                    }
                }
                throw $_
            }
        }
    }
    end {
        $result
    }
}
