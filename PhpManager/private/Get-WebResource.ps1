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
        $BreakingStatusCodes = @(
            401, # Unauthorized
            402, # Payment Required
            403, # Forbidden
            404, # Not Found
            405, # Method Not Allowed
            407, # Proxy Authentication Required
            413, # Payload Too Large
            414, # URI Too Long
            415, # Unsupported Media Type
            426, # Upgrade Required
            431, # Request Header Fields Too Large
            451, # Unavailable For Legal Reasons
            501, # Not Implemented
            505  # HTTP Version Not Supported
        )
    }
    process {
        if ($null -eq $OutFile) {
            $OutFile = '';
        }
        for ($cycle = 1; $cycle -le $Retries; $cycle++) {
            try {
                if ($OutFile -eq '') {
                    $result = Invoke-WebRequest -Uri $Uri -UseBasicParsing -Verbose:$false
                } else {
                    $result = Invoke-WebRequest -Uri $Uri -UseBasicParsing -Verbose:$false -OutFile $OutFile
                }
                break
            } catch [System.Net.WebException] {
                if ($cycle -eq $Retries) {
                    throw
                }
                if ($_.Exception -and $_.Exception.Response -and $BreakingStatusCodes.Contains([int]$_.Exception.Response.StatusCode)) {
                    throw
                }
                Write-Verbose "Downloading from $Uri failed, retrying..."
            } catch {
                if ($cycle -eq $Retries) {
                    throw
                }
                Write-Verbose "Downloading from $Uri failed, retrying..."
            }
        }
    }
    end {
        $result
    }
}
