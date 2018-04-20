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
        If ($Path -eq $null -or $Path -eq '') {
            $installedVersion = Get-OnePhpVersionFromEnvironment
            $confirmAutomaticallyFoundPhp = $true
        } Else {
            $installedVersion = Get-PhpVersionFromPath -Path $Path
            $confirmAutomaticallyFoundPhp = $false
        }
        $folder = [System.IO.Path]::GetDirectoryName($installedVersion.ExecutablePath)
        If ($confirmAutomaticallyFoundPhp -and -Not($ConfirmAuto)) {
            Write-Host "The PHP installation has been found at $folder"
            $confirmed = $false
            While (-Not($confirmed)) {
                $answer = Read-Host -Prompt "Do you confirm updating this installation [use -ConfirmAuto to confirm autumatically]? [y/n]"
                If ($answer -match '^\s*y') {
                    $confirmed = $true
                } ElseIf ($answer -match '^\s*n') {
                    throw 'Operation aborted.'
                } Else {
                    Write-Host 'Please answer with Y or N'
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
            $compatibleVersions = Get-PhpAvailableVersions -State $possibleReleaseState | Where-Object {Get-PhpVersionsCompatibility -A $installedVersion -B $_}
            if ($compatibleVersions -ne $null) {
                break
            }
        }
        $bestNewVersion = $null
        if ($compatibleVersions -ne $null) {
            ForEach ($compatibleVersion in $compatibleVersions) {
                If ($bestNewVersion -eq $null) {
                    $bestNewVersion = $compatibleVersion
                } ElseIf ($(Compare-PhpVersions -A $compatibleVersion -B $bestNewVersion) -gt 0) {
                    $bestNewVersion = $compatibleVersion
                }
            }
        }
        if ($bestNewVersion -eq $null) {
            Write-Host 'No PHP compatible version found'
            $updated = $false
        } else {
            if (-Not($Force) -and $(Compare-PhpVersions -A $bestNewVersion -B $installedVersion) -le 0) {
                Write-Host $('No new version available (latest version is ' + $bestNewVersion.FullVersion + ')')
                $updated = $false
            } else {
                Write-Host $('Installing new version: ' + $bestNewVersion.DisplayName)
                Install-PhpFromUrl -Url $bestNewVersion.DownloadUrl -Path ([System.IO.Path]::GetDirectoryName($installedVersion.ExecutablePath))
                $updated = $true
            }
        }
    }
    End {
        $updated
    }
}
