Function New-TempDirectory
{
    <#
    .Synopsis
    Creates a new temporary directory

    .Outputs
    string
    #>
    Param (
    )
    Begin {
        $result = $null
    }
    Process {
        $tempContainer = [System.IO.Path]::GetTempPath()
        For (;;) {
            $result = Join-Path -Path $tempContainer -ChildPath ([System.IO.Path]::GetRandomFileName())
            If (-Not(Test-Path -Path $result)) {
                New-Item -Path $result -ItemType Directory | Out-Null
                break
            }
        }
    }
    End {
        $result
    }
}
