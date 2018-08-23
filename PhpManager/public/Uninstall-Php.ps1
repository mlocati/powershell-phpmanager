function Uninstall-Php() {
    <#
    .Synopsis
    Uninstalls PHP.

    .Description
    Remove an installed PHP version.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter ConfirmAuto
    If -Path is omitted, specify this flag to assume that the PHP installation found in PATH is the correct one.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $ConfirmAuto
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
            $confirmAutomaticallyFoundPhp = $true
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
            $confirmAutomaticallyFoundPhp = $false
        }
        if ($confirmAutomaticallyFoundPhp -and -Not($ConfirmAuto)) {
            Write-Verbose "The PHP installation has been found at $($phpVersion.ActualFolder)"
            $confirmed = $false
            while (-Not($confirmed)) {
                $answer = Read-Host -Prompt "Do you confirm removing PHP from $($phpVersion.ActualFolder) [use -ConfirmAuto to confirm autumatically]? [y/n]"
                if ($answer -match '^\s*y') {
                    $confirmed = $true
                } elseif ($answer -match '^\s*n') {
                    throw 'Operation aborted.'
                } else {
                    Write-Error 'Please answer with Y or N' -ErrorAction Continue
                }
            }
        }
        Remove-Item -LiteralPath $phpVersion.ActualFolder -Recurse -Force
        Edit-FolderInPath -Operation Remove -Path $phpVersion.ActualFolder
        if ($phpVersion.Folder -ne $phpVersion.ActualFolder) {
            Edit-FolderInPath -Operation Remove -Path $phpVersion.Folder
        }
        Write-Verbose ($phpVersion.DisplayName + ' has been uninstalled from ' + $phpVersion.ActualFolder)
    }
    end {
    }
}
