function Get-PhpAvailableVersion
{
    <#
    .Synopsis
    Gets the list of available versions.

    .Parameter State
    The release state (can be 'Release', 'Archive', 'QA', or 'Snapshot').

    .Parameter Reload
    Force the reload of the list.

    .Outputs
    System.Array

    .Example
    Get-PhpAvailableVersion -State Release
    #>
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The release state (can be ''Release'' or ''Archive'' or ''QA'' or ''Snapshot'')')]
        [ValidateSet('Release', 'QA', 'Archive', 'Snapshot')]
        [string]$State,
        [Parameter(Mandatory = $false, HelpMessage = 'Force the reload of the list')]
        [switch]$Reload
    )
    begin {
        $result = $null
    }
    process {
        $listVariableName = "AVAILABLEVERSIONS_$State".ToUpper()
        if (-Not $Reload) {
            $result = Get-Variable -Name $listVariableName -ValueOnly -Scope Script
        }
        if ($null -eq $result) {
            $result = @()
            $urlList = Get-Variable -Name "URL_LIST_$State" -ValueOnly -Scope Script
            switch ($State) {
                $Script:RELEASESTATE_SNAPSHOT {
                    function Get-ArtifactFlag([bool]$threadSafe, [string][ValidateSet('x86', 'x64')]$architecture) {
                        if ($architecture -eq 'x86') {
                            if ($threadSafe) {
                                return 1
                            }
                            return 2
                        }
                        if ($threadSafe) {
                            return 4
                        }
                        return 8
                    }
                    Write-Verbose "Fetching snapshots version list from $urlList"
                    foreach ($versionLink in (Invoke-WebRequest -UseBasicParsing -Uri $urlList -Verbose:$false).Links) {
                        if (-not($versionLink | Get-Member -Name 'HREF')) {
                            continue
                        }
                        $match = $versionLink.Href | Select-String -Pattern '/(master|php-\d+\.\d+)/?$'
                        if ($null -eq $match) {
                            continue
                        }
                        $versionSlug = $match.Matches[0].Groups[1].Value
                        $snapshotsUrl = [Uri]::new([Uri]$urlList, $versionLink.Href).AbsoluteUri.TrimEnd('/')
                        <#
                        Now we parse the rXXXXXX folders, starting from the last one.
                        We look for PHP .zip files in each folder, looking for the 4 versions (thread safe/non threadsafe, x86/x64).
                        Once we find all the 4 versions, we stop parsing the rXXXXXX folders.
                        #>
                        $missingArtifactFlags = 0
                        $missingArtifactFlags = $missingArtifactFlags -bor (Get-ArtifactFlag $false 'x86')
                        $missingArtifactFlags = $missingArtifactFlags -bor (Get-ArtifactFlag $false 'x64')
                        $missingArtifactFlags = $missingArtifactFlags -bor (Get-ArtifactFlag $true 'x86')
                        $missingArtifactFlags = $missingArtifactFlags -bor (Get-ArtifactFlag $true 'x64')
                        Write-Verbose "Fetching snapshots build list for $versionSlug from $snapshotsUrl"
                        $buildLinks = (Invoke-WebRequest -UseBasicParsing -Uri "$snapshotsUrl/" -Verbose:$false).Links
                        for ($buildLinkIndex = $buildLinks.Count - 1; $buildLinkIndex -ge 0 -and $missingArtifactFlags -ne 0; $buildLinkIndex--) {
                            $buildLink = $buildLinks[$buildLinkIndex]
                            if (-not($buildLink | Get-Member -Name 'HREF')) {
                                continue
                            }
                            $match = $buildLink.Href | Select-String -Pattern '/(r[0-9a-f]{7,})/?$'
                            if ($null -eq $match) {
                                continue
                            }
                            $artifactsUrl = [Uri]::new([Uri]"$snapshotsUrl/", $buildLink.Href).AbsoluteUri.TrimEnd('/')
                            Write-Verbose "Fetching snapshots artifact list from $artifactsUrl"
                            foreach ($artifactsLink in (Invoke-WebRequest -UseBasicParsing -Uri "$artifactsUrl/" -Verbose:$false).Links) {
                                if (-not($artifactsLink | Get-Member -Name 'HREF')) {
                                    continue
                                }
                                $artifactUrl = [Uri]::new([Uri]"$artifactsUrl/", $artifactsLink.HREF).AbsoluteUri
                                if (-not($artifactUrl -match $Script:RX_ZIPARCHIVE_SNAPSHOT)) {
                                    continue
                                }
                                $artifactVersion = Get-PhpVersionFromUrl -Url $artifactUrl -ReleaseState $State
                                $artifactFlag = Get-ArtifactFlag $artifactVersion.ThreadSafe $artifactVersion.Architecture
                                if (($artifactFlag -band $missingArtifactFlags) -eq 0) {
                                    continue
                                }
                                $result += $artifactVersion
                                $missingArtifactFlags = $missingArtifactFlags -band -bnot $artifactFlag
                            }
                        }
                    }
                    if ($true) {
                        $result += Get-PhpVersionFromUrl -Url 'https://github.com/shivammathur/php-builder-windows/releases/download/master/php-master-nts-windows-vs16-x64.zip' -ReleaseState $State
                        $result += Get-PhpVersionFromUrl -Url 'https://github.com/shivammathur/php-builder-windows/releases/download/master/php-master-ts-windows-vs16-x64.zip' -ReleaseState $State
                        $result += Get-PhpVersionFromUrl -Url 'https://github.com/shivammathur/php-builder-windows/releases/download/master/php-master-nts-windows-vs16-x86.zip' -ReleaseState $State
                        $result += Get-PhpVersionFromUrl -Url 'https://github.com/shivammathur/php-builder-windows/releases/download/master/php-master-ts-windows-vs16-x86.zip' -ReleaseState $State
                    }
                }
                default {
                    Set-NetSecurityProtocolType
                    $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $urlList
                    foreach ($link in $webResponse.Links | Where-Object -Property 'Href' -Match ('/' + $Script:RX_ZIPARCHIVE + '$')) {
                        $result += Get-PhpVersionFromUrl -Url $link.Href -ReleaseState $State -PageUrl $urlList
                    }
                }
            }
            Set-Variable -Scope Script -Name $listVariableName -Value $result -Force
        }
    }
    end {
        $result
    }
}
