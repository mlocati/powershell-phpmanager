function Test-IsFileWritable {
    <#
    .Synopsis
    Check if one or more existing files are writable

    .Parameter Path
    The path to the file.

    .Parameter IfNotExist
    How to consider the case if Path is not a file ($false: file is not writable, $true: file is writable - default: $true)
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 1)]
        [bool]$IfNotExist = $true
    )
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            [System.IO.File]::OpenWrite($Path).Close()
            $result = $true
        }
        catch [System.IO.IOException] {
            Write-Verbose $_.Exception.Message
            $result = $false
        }
    }
    else {
        $result = $IfNotExist
    }
    $result
}
