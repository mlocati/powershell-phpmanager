Function Get-PeclDlls
{
    <#
    .Synopsis
    Gets the list of DLLs available for a PECL package.

    .Parameter Handle
    The handle of the package.

    .Parameter Version
    The version of the package.

    .Parameter PhpVersion
    The PhpVersion instance for which you want the PECL packages.

    .Parameter MinimumStability
    The minimum stability of the package.

    .Outputs
    System.Array
    #>
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Handle,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Version,
        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNull()]
        [psobject] $PhpVersion,
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MinimumStability = 'stable'
    )
    Begin {
        $result = @()
    }
    Process {
        # https://github.com/php/web-pecl/blob/467593b248d4603a3dee2ecc3e61abfb7434d24d/include/pear-win-package.php
        $handleLC = $Handle.ToLowerInvariant();
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 + [Net.SecurityProtocolType]::Tls11 + [Net.SecurityProtocolType]::Tls
        }
        Catch {
            Write-Debug '[Net.ServicePointManager] or [Net.SecurityProtocolType] not found in current environment'
        }
        $rxMatch = '/php_' + [regex]::Escape($Handle)
        $rxMatch += '-' + [regex]::Escape($Version)
        $rxMatch += '-' + [regex]::Escape('' + $phpVersion.ComparableVersion.Major + '.' + $phpVersion.ComparableVersion.Minor)
        $rxMatch += '-' + $(If ($phpVersion.ThreadSafe) { 'ts' } Else {'nts'} )
        $rxMatch += '-vc' + $phpVersion.VCVersion
        $rxMatch += '-' + [regex]::Escape($PhpVersion.Architecture)
        $rxMatch += '\.zip$'
        $urls = @("https://windows.php.net/downloads/pecl/releases/$handleLC/$Version")
        If ($MinimumStability -eq $Script:PEARSTATE_SNAPSHOT) {
            $urls += "https://windows.php.net/downloads/pecl/snaps/$handleLC/$Version"
        }
        ForEach ($url in $urls) {
            Try {
                $webResponse = Invoke-WebRequest -UseBasicParsing -Uri $url
            }
            Catch [System.Net.WebException] {
                If ($_.Exception -and $_.Exception.Response -and $_.Exception.Response.StatusCode -eq 404) {
                    continue
                }
            }
            ForEach ($link In $webResponse.Links) {
                $linkUrl = [Uri]::new([Uri]$url, $link.Href).AbsoluteUri
                $match = $linkUrl | Select-String -Pattern $rxMatch
                If ($match) {
                    $r1 = New-Object PSObject
                    $r1 | Add-Member -MemberType NoteProperty -Name 'Package' -Value $Handle
                    $r1 | Add-Member -MemberType NoteProperty -Name 'Version' -Value $Version
                    $r1 | Add-Member -MemberType NoteProperty -Name 'Url' -Value $linkUrl
                    $r1 | Add-Member -MemberType NoteProperty -Name 'PhpVersion' -Value $match.Matches[0].Groups[1].Value
                    $r1 | Add-Member -MemberType NoteProperty -Name 'ThreadSafe' -Value ($match.Matches[0].Groups[2].Value -eq 'ts')
                    $r1 | Add-Member -MemberType NoteProperty -Name 'VCVersion' -Value ([int]$match.Matches[0].Groups[3].Value)
                    $r1 | Add-Member -MemberType NoteProperty -Name 'Architecture' -Value $match.Matches[0].Groups[4].Value
                    $result += $r1
                }
            }
            If ($result.Count -gt 0) {
                break
            }
        }
    }
    End {
        $result
    }
}
