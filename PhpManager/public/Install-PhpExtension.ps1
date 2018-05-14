function Install-PhpExtension() {
    <#
    .Synopsis
    Installs a PHP extension.

    .Description
    Downloads a PHP extension, or move a local file to the correct location, and enables it (if the -DontEnable switch is not specified).

    .Parameter Extension
    The name of the PHP extension to be downloaded, or the path to an already downloaded file.

    .Parameter Version
    Specify the version of the extension (it can be for example '2.6.0', '2.6', '2').

    .Parameter MinimumStability
    The minimum stability flag of the package: one of 'stable' (default), 'beta', 'alpha', 'devel' or 'snapshot'.

    .Parameter DontEnable
    Specify this switch to not enable the extension.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name of the PHP extension to be downloaded, or the path to an already downloaded file')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Specify the version of the extension (it can be for example ''2.6.0'', ''2.6'', ''2'')')]
        [ValidateNotNull()]
        [ValidatePattern('^\d+(\.\d+){0,2}$')]
        [string] $Version,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The minimum stability flag of the package: one of ''stable'' (default), ''beta'', ''alpha'', ''devel'' or ''snapshot'')')]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MinimumStability,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $DontEnable
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $tempFolder = $null
        try {
            if (Test-Path -Path $Extension -PathType Leaf) {
                if ($null -ne $Version -and $Version -ne '') {
                    throw 'You can''t specify the -Version argument if you specify an existing file with the -Extension argument'
                }
                if ($null -ne $MinimumStability -and $MinimumStability -ne '') {
                    throw 'You can''t specify the -MinimumStability argument if you specify an existing file with the -Extension argument'
                }
                $dllPath = [System.IO.Path]::GetFullPath($Extension)
            } else {
                if ($null -eq $MinimumStability -or $MinimumStability -eq '') {
                    $MinimumStability = $Script:PEARSTATE_STABLE
                }
                $peclPackages = @(Get-PeclAvailablePackage)
                $foundPeclPackages = @($peclPackages | Where-Object { $_ -eq $Extension })
                if ($foundPeclPackages.Count -ne 1) {
                    $foundPeclPackages = @($peclPackages | Where-Object { $_ -like "*$Extension*" })
                    if ($foundPeclPackages.Count -eq 0) {
                        throw "No PECL extensions found containing '$Extension'"
                    }
                    if ($foundPeclPackages.Count -ne 1) {
                        throw ("Multiple PECL extensions found containing '$Extension':`n - " + [String]::Join("`n - ", $foundPeclPackages))
                    }
                }
                $peclPackageHandle = $foundPeclPackages[0]
                $peclPackageVersions = @(Get-PeclPackageVersion -Handle $peclPackageHandle -Version $Version -MinimumStability $MinimumStability)
                if ($peclPackageVersions.Count -eq 0) {
                    if ($null -eq $Version -or $Version -eq '') {
                        throw "The PECL package $peclPackageHandle does not have any version with a $MinimumStability minimum stability"
                    }
                    throw "The PECL package $peclPackageHandle does not have any $Version version with a $MinimumStability minimum stability"
                }
                $availablePackageVersion = $null
                foreach ($peclPackageVersion in $peclPackageVersions) {
                    $archiveUrl = Get-PeclArchiveUrl -PackageHandle $peclPackageHandle -PackageVersion $peclPackageVersion -PhpVersion $phpVersion -MinimumStability $MinimumStability
                    if ($archiveUrl -eq '') {
                        Write-Verbose ("No Windows DLLs found for PECL package {0} {1} compatible with {2}" -f $peclPackageHandle, $peclPackageVersion, $phpVersion.DisplayName)
                    } else {
                        $availablePackageVersion = @{PackageVersion = $peclPackageVersion; PackageArchiveUrl = $archiveUrl}
                        break
                    }
                }
                if ($null -eq $availablePackageVersion) {
                    throw "No compatible Windows DLL found for PECL package $peclPackageHandle with a $MinimumStability minimum stability"
                }
                Write-Verbose ("Downloading PECL package {0} {1} from {2}" -f $peclPackageHandle, $availablePackageVersion.PackageVersion, $availablePackageVersion.PackageArchiveUrl)
                $zip, $keepZip = Get-FileFromUrlOrCache -Url $availablePackageVersion.PackageArchiveUrl
                try {
                    $tempFolder = New-TempDirectory
                    Expand-ArchiveWith7Zip -ArchivePath $zip -DestinationPath $tempFolder
                    $phpDlls = @(Get-ChildItem -Path $tempFolder\php_*.dll -File -Depth 0)
                    if ($phpDlls.Count -eq 0) {
                        $phpDlls = @(Get-ChildItem -Path $tempFolder\php_*.dll -File -Depth 1)
                    }
                    if ($phpDlls.Count -eq 0) {
                        throw ("No PHP DLL found in archive downloaded from {0}" -f $availablePackageVersion.PackageArchiveUrl)
                    }
                    if ($phpDlls.Count -ne 1) {
                        throw ("Multiple PHP DLL found in archive downloaded from {0}" -f $availablePackageVersion.PackageArchiveUrl)
                    }
                    $dllPath = $phpDlls[0].FullName
                } catch {
                    $keepZip = $false
                    throw
                } finally {
                    if (-Not($keepZip)) {
                        try {
                            Remove-Item -Path $zip -Force
                        } catch {
                            Write-Debug 'Failed to remove temporary zip file'
                        }
                    }
                }
            }
            $newExtension = Get-PhpExtensionDetail -PhpVersion $phpVersion -Path $dllPath
            $oldExtension = Get-PhpExtension -Path $phpVersion.ExecutablePath | Where-Object {$_.Handle -eq $newExtension.Handle}
            if ($null -ne $oldExtension) {
                if ($oldExtension.Type -eq $Script:EXTENSIONTYPE_BUILTIN) {
                    Write-Verbose ("'{0}' is a builtin extension" -f $oldExtension.Name)
                }
                Write-Verbose ("Upgrading extension '{0}' from version {1} to version {2}" -f $oldExtension.Name, $oldExtension.Version, $newExtension.Version)
                Move-Item -Path $dllPath -Destination $oldExtension.Filename -Force
                if ($oldExtension.State -eq $Script:EXTENSIONSTATE_DISABLED -and -Not($DontEnable)) {
                    Enable-PhpExtension -Extension $oldExtension.Name -Path $phpVersion.ExecutablePath
                }
            } else {
                Write-Verbose ("Installing new extension '{0}' version {1}" -f $newExtension.Name, $newExtension.Version)
                Install-PhpExtensionPrerequisite -PhpVersion $phpVersion -Extension $newExtension
                $newExtensionFilename = [System.IO.Path]::Combine($phpVersion.ExtensionsPath, [System.IO.Path]::GetFileName($dllPath))
                Move-Item -Path $dllPath -Destination $newExtensionFilename
                if (-Not($DontEnable)) {
                    Enable-PhpExtension -Extension $newExtension.Name -Path $phpVersion.ExecutablePath
                }
            }
        } finally {
            if ($null -ne $tempFolder) {
                try {
                    Remove-Item -Path $tempFolder -Recurse -Force
                } catch {
                    Write-Debug 'Failed to remove temporary folder'
                }
            }
        }
    }
    end {
    }
}
