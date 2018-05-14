function New-TempDirectory
{
    <#
    .Synopsis
    Creates a new temporary directory

    .Outputs
    string
    #>
    [OutputType([string])]
    param (
    )
    begin {
        $result = $null
    }
    process {
        $tempContainer = [System.IO.Path]::GetTempPath()
        for (;;) {
            $result = Join-Path -Path $tempContainer -ChildPath ([System.IO.Path]::GetRandomFileName())
            if (-Not(Test-Path -Path $result)) {
                New-Item -Path $result -ItemType Directory | Out-Null
                break
            }
        }
    }
    end {
        $result
    }
}
