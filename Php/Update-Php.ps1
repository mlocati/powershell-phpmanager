function Update-Php() {
    <#
    .Synopsis
    Updates PHP.

    .Description
    Checks if a new PHP version is available: if so updates an existing PHP installation.

    .Parameter Path
    The path of the directory where PHP is installed.

    .Parameter Force
    Use this switch to force updating PHP even if the newest available version is not newer than the installed one.

    .Outputs
    bool
    #>
    Param(
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path of the directory where PHP is installed')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $Force
    )
    Begin {
        $updated = $null
    }
    Process {
        $Path = [System.IO.Path]::GetFullPath($Path)
        # Check existency
        If (Test-Path -Path $Path -PathType Leaf) {
            If ($([System.IO.Path]::GetFileName($Path)) -ne 'php.exe') {
                Throw 'Path must be the name of a directory (or the path to php.exe).'
            }
            $Path = [System.IO.Path]::GetDirectoryName($Path)
        } ElseIf (-Not(Test-Path -Path $Path -PathType Container)) {
            Throw 'Unable to find the Path specified.'
        }
        $executablePath = [System.IO.Path]::Combine($Path, 'php.exe')
        If (-Not(Test-Path -Path $executablePath -PathType Leaf)) {
            Throw 'Unable to find the PHP executable in the specified Path.'
        }
        $installedVersion = Get-PhpVersionFromExecutable -ExecutablePath $executablePath
        Write-Host $('Found PHP version: ' + $installedVersion.DisplayName)
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
                Install-PhpFromUrl -Url $bestNewVersion.DownloadUrl -Path $Path
                $updated = $true
            }
        }
    }
    End {
        $updated
    }
}