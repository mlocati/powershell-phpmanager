function Update-Php() {
    <#
    .Synopsis
    Updates PHP.

    .Description
    Checks if a new PHP version is available: if so updates an existing PHP installation.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter Force
    Use this switch to force updating PHP even if the newest available version is not newer than the installed one.

    .Outputs
    bool
    #>
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $Force
    )
    begin {
        $updated = $null
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $installedVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $installedVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $possibleReleaseStates = @()
        if ($installedVersion.UnstabilityLevel -eq $Script:UNSTABLEPHP_SNAPSHOT) {
            $possibleReleaseStates += $Script:RELEASESTATE_SNAPSHOT
        } else {
            $possibleReleaseStates += $Script:RELEASESTATE_RELEASE
            if ($installedVersion.UnstabilityLevel -ne '') {
                $possibleReleaseStates += $Script:RELEASESTATE_QA
            }
            $possibleReleaseStates += $Script:RELEASESTATE_ARCHIVE
        }
        $compatibleVersions = $null
        $availableSnapshots = $null
        foreach ($possibleReleaseState in $possibleReleaseStates) {
            $availableVersions = Get-PhpAvailableVersion -State $possibleReleaseState
            if ($possibleReleaseStates -eq $Script:RELEASESTATE_SNAPSHOT) {
                $availableSnapshots = $availableVersions
            }
            $compatibleVersions = $availableVersions | Where-Object { Get-PhpVersionsCompatibility -A $installedVersion -B $_ }
            if ($null -ne $compatibleVersions) {
                break
            }
        }
        if (-not($compatibleVersions) -and $installedVersion.UnstabilityLevel -eq $Script:UNSTABLEPHP_SNAPSHOT) {
            # Let's install "master"
            $compatibleVersions = $availableSnapshots | Where-Object { $_.Version -eq 'master' -and (Get-PhpVersionsCompatibility -A $installedVersion -B $_ -SkipVersionCheck $true) }
        }
        $bestNewVersion = $null
        if ($null -ne $compatibleVersions) {
            foreach ($compatibleVersion in $compatibleVersions) {
                if ($null -eq $bestNewVersion) {
                    $bestNewVersion = $compatibleVersion
                } elseif ($compatibleVersion.CompareTo($bestNewVersion) -gt 0) {
                    $bestNewVersion = $compatibleVersion
                }
            }
        }
        if ($null -eq $bestNewVersion) {
            Write-Verbose 'No PHP compatible version found'
            $updated = $false
        } else {
            if (-Not($Force) -and $bestNewVersion.CompareTo($installedVersion) -le 0) {
                Write-Verbose "No new version available (latest version is $($bestNewVersion.FullVersion))"
                $updated = $false
            } else {
                Write-Verbose "Installing new version $($bestNewVersion.DisplayName) over $($installedVersion.DisplayName)"
                Install-PhpFromUrl -Url $bestNewVersion.DownloadUrl -Path $installedVersion.ActualFolder -PhpVersion $bestNewVersion -InstallVCRedist $false
                $updated = $true
            }
        }
    }
    end {
        $updated
    }
}
