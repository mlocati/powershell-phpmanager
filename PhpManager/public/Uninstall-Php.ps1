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
    Param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $ConfirmAuto
    )
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
            $confirmAutomaticallyFoundPhp = $true
        } Else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
            $confirmAutomaticallyFoundPhp = $false
        }
        If ($confirmAutomaticallyFoundPhp -and -Not($ConfirmAuto)) {
            Write-Output "The PHP installation has been found at $($phpVersion.ActualFolder)"
            $confirmed = $false
            While (-Not($confirmed)) {
                $answer = Read-Host -Prompt "Do you confirm removing this installation [use -ConfirmAuto to confirm autumatically]? [y/n]"
                If ($answer -match '^\s*y') {
                    $confirmed = $true
                } ElseIf ($answer -match '^\s*n') {
                    throw 'Operation aborted.'
                } Else {
                    Write-Output 'Please answer with Y or N'
                }
            }
        }
        Remove-Item -LiteralPath $phpVersion.ActualFolder -Recurse -Force
        Edit-PhpFolderInPath -Operation Remove -Path $phpVersion.ActualFolder
        If ($phpVersion.Folder -ne $phpVersion.ActualFolder) {
            Edit-PhpFolderInPath -Operation Remove -Path $phpVersion.Folder
        }
        Write-Output ($phpVersion.DisplayName + ' has been uninstalled from ' + $phpVersion.ActualFolder)
    }
    End {
    }
}
