function Reset-Acl() {
    <#
    .Synopsis
    Reset the Access-control list of files/folders so that they inherit the parent permissions.

    .Parameter Path
    The path(s) of the file(s)/folder(s).
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The path(s) of the file(s)/folder(s)')]
        [ValidateNotNull()]
        [psobject[]] $Path
    )
    begin {
    }
    process {
        foreach ($childPath in $Path) {
            if ($childPath -is [System.IO.FileSystemInfo]) {
                $child = $childPath
            } else {
                $child = Get-Item -Path $childPath
            }
            if ($child -is [System.IO.DirectoryInfo]) {
                $acl = New-Object System.Security.AccessControl.DirectorySecurity
            }
            elseif ($child -is [System.IO.FileInfo]) {
                $acl = New-Object System.Security.AccessControl.FileSecurity
            }
            else {
                throw "$childPath is neither a file nor a directory"
            }
            $acl.SetAccessRuleProtection($false, $true)
            Set-Acl -Path $childPath -AclObject $acl
            $acl = $null
        }
    }
    end {
    }
}
