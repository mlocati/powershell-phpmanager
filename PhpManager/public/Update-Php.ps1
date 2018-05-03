function Update-Php() {
    <#
    .Synopsis
    Updates PHP.

    .Description
    Checks if a new PHP version is available: if so updates an existing PHP installation.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter ConfirmAuto
    If -Path is omitted, specify this flag to assume that the PHP installation found in PATH is the correct one.

    .Parameter Force
    Use this switch to force updating PHP even if the newest available version is not newer than the installed one.

    .Outputs
    bool
    #>
    Param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $ConfirmAuto,
        [switch] $Force
    )
    Begin {
        $updated = $null
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $installedVersion = [PhpVersionInstalled]::FromEnvironmentOne()
            $confirmAutomaticallyFoundPhp = $true
        } Else {
            $installedVersion = [PhpVersionInstalled]::FromPath($Path)
            $confirmAutomaticallyFoundPhp = $false
        }
        If ($confirmAutomaticallyFoundPhp -and -Not($ConfirmAuto)) {
            Write-Output "The PHP installation has been found at $($installedVersion.ActualFolder))"
            $confirmed = $false
            While (-Not($confirmed)) {
                $answer = Read-Host -Prompt "Do you confirm updating this installation [use -ConfirmAuto to confirm autumatically]? [y/n]"
                If ($answer -match '^\s*y') {
                    $confirmed = $true
                } ElseIf ($answer -match '^\s*n') {
                    throw 'Operation aborted.'
                } Else {
                    Write-Output 'Please answer with Y or N'
                }
            }
        }
        if ($installedVersion.RC -eq '') {
            $possibleReleaseStates = @($Script:RELEASESTATE_RELEASE, $Script:RELEASESTATE_ARCHIVE)
        } else {
            $possibleReleaseStates = @($Script:RELEASESTATE_QA)
        }
        $compatibleVersions = $null
        foreach ($possibleReleaseState in $possibleReleaseStates) {
            $compatibleVersions = Get-PhpAvailableVersion -State $possibleReleaseState | Where-Object {Get-PhpVersionsCompatibility -A $installedVersion -B $_}
            if ($null -ne $compatibleVersions) {
                break
            }
        }
        $bestNewVersion = $null
        if ($null -ne $compatibleVersions) {
            ForEach ($compatibleVersion in $compatibleVersions) {
                If ($null -eq $bestNewVersion) {
                    $bestNewVersion = $compatibleVersion
                } ElseIf ($compatibleVersion -gt $bestNewVersion) {
                    $bestNewVersion = $compatibleVersion
                }
            }
        }
        if ($null -eq $bestNewVersion) {
            Write-Output 'No PHP compatible version found'
            $updated = $false
        } else {
            if (-Not($Force) -and $bestNewVersion -le $installedVersion) {
                Write-Output $('No new version available (latest version is ' + $bestNewVersion.FullVersion + ')')
                $updated = $false
            } else {
                Write-Output $('Installing new version: ' + $bestNewVersion.DisplayName)
                Install-PhpFromUrl -Url $bestNewVersion.DownloadUrl -Path $installedVersion.ActualFolder -PhpVersion $bestNewVersion -InstallVCRedist $false
                $updated = $true
            }
        }
    }
    End {
        $updated
    }
}
