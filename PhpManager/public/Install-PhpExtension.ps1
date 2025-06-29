﻿function Install-PhpExtension() {
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

    .Parameter MaximumStability
    The maximum stability flag of the package: one of 'stable' (default), 'beta', 'alpha', 'devel' or 'snapshot'.

    .Parameter DontEnable
    Specify this switch to not enable the extension.

    .Parameter Path
    The path of the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter NoDependencies
    Skip the installation of extension dependencies (youl'll have to manually call Install-PhpExtensionPrerequisite before calling Install-PhpExtension).
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name of the PHP extension to be downloaded, or the path to an already downloaded file')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Specify the version of the extension (it can be for example ''2.6.0'', ''2.6'', ''2'')')]
        [ValidateNotNull()]
        [ValidatePattern('^\d+(\.\d+){0,3}$')]
        [string] $Version,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The minimum stability flag of the package: one of ''stable'' (default), ''beta'', ''alpha'', ''devel'' or ''snapshot'')')]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MinimumStability,
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = 'The maximum stability flag of the package: one of ''stable'' (default), ''beta'', ''alpha'', ''devel'' or ''snapshot'')')]
        [ValidateNotNull()]
        [ValidateSet('stable', 'beta', 'alpha', 'devel', 'snapshot')]
        [string] $MaximumStability,
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = 'The path where additional files (DLL, ...) will be installed; if omitted we''ll use the directory where PHP resides')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $AdditionalFilesPath,
        [switch] $DontEnable,
        [switch] $NoDependencies
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        }
        else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        if ($phpVersion.ExtensionsPath -eq '') {
            throw 'The PHP extension directory is not configured. You may need to set the extension_dir setting in the php.ini file'
        }
        if (-Not(Test-Path -LiteralPath $phpVersion.ExtensionsPath -PathType Container)) {
            throw "The PHP extension directory ""$($phpVersion.ExtensionsPath)"" configured in your php.ini does not exist. You may need to create it, or fix the extension_dir setting in the php.ini file."
        }
        if ($null -eq $AdditionalFilesPath -or $AdditionalFilesPath -eq '') {
            $AdditionalFilesPath = $phpVersion.ActualFolder
        } elseif (-Not(Test-Path -LiteralPath $AdditionalFilesPath -PathType Container)) {
            throw "The directory ""$AdditionalFilesPath"" where additional files should be saved does not exist."
        }
        if ($null -eq $Version) {
            $Version = ''
        }
        $tempFolder = $null
        $finalDllName = $null
        $additionalFiles = @()
        $newExtensions = @()
        try {
            if (Test-Path -Path $Extension -PathType Leaf) {
                if ($Version -ne '') {
                    throw 'You can''t specify the -Version argument if you specify an existing file with the -Extension argument'
                }
                if ($null -ne $MinimumStability -and $MinimumStability -ne '') {
                    throw 'You can''t specify the -MinimumStability argument if you specify an existing file with the -Extension argument'
                }
                if ($null -ne $MaximumStability -and $MaximumStability -ne '') {
                    throw 'You can''t specify the -MaximumStability argument if you specify an existing file with the -Extension argument'
                }
                $dllPath = [System.IO.Path]::GetFullPath($Extension)
                $newExtensions += Get-PhpExtensionDetail -PhpVersion $phpVersion -Path $dllPath
                $moveDll = $false
            }
            else {
                if ($null -eq $MinimumStability -or $MinimumStability -eq '') {
                    $MinimumStability = $Script:PEARSTATE_STABLE
                }
                if ($null -eq $MaximumStability -or $MaximumStability -eq '') {
                    $MaximumStability = $Script:PEARSTATE_STABLE
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
                switch ($peclPackageHandle) {
                    'xdebug' {
                        $availablePackageVersion = Get-XdebugExtension -PhpVersion $phpVersion -Version $Version -MinimumStability $MinimumStability -MaximumStability $MaximumStability
                        if ($null -ne $availablePackageVersion) {
                            $remoteFileIsZip = $false
                            $finalDllName = 'php_xdebug.dll'
                        }
                    }
                    default {
                        $availablePackageVersion = $null
                    }
                }
                if ($null -eq $availablePackageVersion) {
                    $peclPackageVersions = @(Get-PeclPackageVersion -Handle $peclPackageHandle -Version $Version -MinimumStability $MinimumStability -MaximumStability $MaximumStability)
                    if ($peclPackageVersions.Count -eq 0) {
                        if ($Version -eq '') {
                            throw "The PECL package $peclPackageHandle does not have any version with a stability between $MinimumStability and $MaximumStability"
                        }
                        throw "The PECL package $peclPackageHandle does not have any $Version version with a stability between $MinimumStability and $MaximumStability"
                    }
                    foreach ($peclPackageVersion in $peclPackageVersions) {
                        $archiveUrl = Get-PeclArchiveUrl -PackageHandle $peclPackageHandle -PackageVersion $peclPackageVersion -PhpVersion $phpVersion -MinimumStability $MinimumStability -MaximumStability $MaximumStability
                        if ($archiveUrl -eq '') {
                            Write-Verbose ("No Windows DLLs found for PECL package {0} {1} compatible with {2}" -f $peclPackageHandle, $peclPackageVersion, $phpVersion.DisplayName)
                        }
                        else {
                            $availablePackageVersion = @{PackageVersion = $peclPackageVersion; PackageArchiveUrl = $archiveUrl }
                            $remoteFileIsZip = $true
                            break
                        }
                    }
                    if ($null -eq $availablePackageVersion) {
                        throw "No compatible Windows DLL found for PECL package $peclPackageHandle with a stability between $MinimumStability and $MaximumStability"
                    }
                }
                Write-Verbose ("Downloading PECL package {0} {1} from {2}" -f $peclPackageHandle, $availablePackageVersion.PackageVersion, $availablePackageVersion.PackageArchiveUrl)
                $downloadedFile, $keepDownloadedFile = Get-FileFromUrlOrCache -Url $availablePackageVersion.PackageArchiveUrl
                try {
                    if ($remoteFileIsZip) {
                        $tempFolder = New-TempDirectory
                        Expand-ArchiveWith7Zip -ArchivePath $downloadedFile -DestinationPath $tempFolder
                        $dllFiles = Get-ChildItem -Path $tempFolder\*.dll -File -Depth 0
                        if (-not($dllFiles)) {
                            $dllFiles = Get-ChildItem -Path $tempFolder\*.dll -File -Depth 1
                            if (-not($dllFiles)) {
                                $dllFiles = @()
                            }
                        }
                        $additionalExtensionsDll = @()
                        $dllNames = $dllFiles | Where-Object -Property Name -Like "php_*.dll" | Select-Object -ExpandProperty Name
                        if ($dllNames -is [array] -and $dllNames.Length -eq 2 -and $dllNames -contains 'php_http.dll' -and $dllNames -contains 'php_raphf.dll') {
                            $newExtensions +=  Get-PhpExtensionDetail -PhpVersion $phpVersion -Path $(Join-Path -Path $tempFolder -ChildPath 'php_raphf.dll')
                            $additionalExtensionsDll += 'php_raphf.dll'
                        }
                        $dllPath = $null
                        foreach ($dllFile in $dllFiles) {
                            if ($additionalExtensionsDll -contains $dllFile.Name) {
                                continue
                            }
                            if ($dllFile.Name -like "php_*.dll") {
                                if ($dllPath) {
                                    throw ("Multiple PHP DLL found in archive downloaded from {0}" -f $availablePackageVersion.PackageArchiveUrl)
                                }
                                $dllPath = $dllFile.FullName
                            } else {
                                $additionalFiles += $dllFile.FullName
                            }
                        }
                        if (-not($dllPath)) {
                            throw ("No PHP DLL found in archive downloaded from {0}" -f $availablePackageVersion.PackageArchiveUrl)
                        }
                    }
                    else {
                        $keepDownloadedFile = $true
                        $dllPath = $downloadedFile
                    }
                    $newExtensions += Get-PhpExtensionDetail -PhpVersion $phpVersion -Path $dllPath
                    $moveDll = $true
                }
                catch {
                    $keepDownloadedFile = $false
                    throw
                }
                finally {
                    if (-Not($keepDownloadedFile)) {
                        try {
                            Remove-Item -Path $downloadedFile -Force
                        }
                        catch {
                            Write-Debug 'Failed to remove temporary zip file'
                        }
                    }
                }
            }
            foreach ($newExtension in $newExtensions) {
                $oldExtension = Get-PhpExtension -Path $phpVersion.ExecutablePath | Where-Object { $_.Handle -eq $newExtension.Handle }
                if ($null -ne $oldExtension) {
                    if ($oldExtension.Type -eq $Script:EXTENSIONTYPE_BUILTIN) {
                        Write-Verbose ("'{0}' is a builtin extension" -f $oldExtension.Name)
                    }
                    Write-Verbose ("Upgrading extension '{0}' from version {1} to version {2}" -f $oldExtension.Name, $oldExtension.Version, $newExtension.Version)
                    if (-Not(Test-IsFileWritable($oldExtension.Filename))) {
                        throw "Unable to write to the file $($oldExtension.Filename)"
                    }
                    if ($moveDll) {
                        Move-Item -Path $newExtension.Filename -Destination $oldExtension.Filename -Force
                    } else {
                        Copy-Item -Path $newExtension.Filename -Destination $oldExtension.Filename -Force
                    }
                    try {
                        Reset-Acl -Path $oldExtension.Filename
                    } catch {
                        Write-Debug -Message "Failed to reset the ACL for $($oldExtension.Filename): $($_.Exception.Message)"
                    }
                    foreach ($additionalFile in $additionalFiles) {
                        $additionalFileDestination = Join-Path -Path $AdditionalFilesPath -ChildPath $(Split-Path -Path $additionalFile -Leaf)
                        Copy-Item -LiteralPath $additionalFile -Destination $additionalFileDestination -Force
                        try {
                            Reset-Acl -Path $additionalFileDestination
                        } catch {
                            Write-Debug -Message "Failed to reset the ACL for $($additionalFileDestination): $($_.Exception.Message)"
                        }
                    }
                    if ($oldExtension.State -eq $Script:EXTENSIONSTATE_DISABLED -and -Not($DontEnable)) {
                        Enable-PhpExtension -Extension $oldExtension.Name -Path $phpVersion.ExecutablePath
                    }
                }
                else {
                    Write-Verbose ("Installing new extension '{0}' version {1}" -f $newExtension.Name, $newExtension.Version)
                    if (-not($NoDependencies)) {
                        Install-PhpExtensionPrerequisite -Extension $newExtension.Handle -InstallPath $AdditionalFilesPath -PhpPath $phpVersion.ActualFolder
                    }
                    if ($null -eq $finalDllName) {
                        $newExtensionFilename = [System.IO.Path]::Combine($phpVersion.ExtensionsPath, [System.IO.Path]::GetFileName($newExtension.Filename))
                    } else {
                        $newExtensionFilename = [System.IO.Path]::Combine($phpVersion.ExtensionsPath, [System.IO.Path]::GetFileName($finalDllName))
                    }
                    if ($moveDll) {
                        Write-Verbose "Moving ""$($newExtension.Filename)"" to ""$newExtensionFilename"""
                        Move-Item -Path $newExtension.Filename -Destination $newExtensionFilename
                    } else {
                        Write-Verbose "Copying ""$($newExtension.Filename)"" to ""$newExtensionFilename"""
                        Copy-Item -Path $newExtension.Filename -Destination $newExtensionFilename
                    }
                    try {
                        Reset-Acl -Path $newExtensionFilename
                    } catch {
                        Write-Debug -Message "Failed to reset the ACL for $($newExtensionFilename): $($_.Exception.Message)"
                    }
                    foreach ($additionalFile in $additionalFiles) {
                        $additionalFileDestination = Join-Path -Path $AdditionalFilesPath -ChildPath $(Split-Path -Path $additionalFile -Leaf)
                        Copy-Item -LiteralPath $additionalFile -Destination $additionalFileDestination -Force
                        try {
                            Reset-Acl -Path $additionalFileDestination
                        } catch {
                            Write-Debug -Message "Failed to reset the ACL for $($additionalFileDestination): $($_.Exception.Message)"
                        }
                    }
                    if (-Not($DontEnable)) {
                        Write-Verbose "Enabling extension ""$($newExtension.Name)"" for ""$($phpVersion.ExecutablePath)"""
                        Enable-PhpExtension -Extension $newExtension.Name -Path $phpVersion.ExecutablePath
                    }
                }
                $additionalFiles = @()
            }
        }
        finally {
            if ($null -ne $tempFolder) {
                try {
                    Remove-Item -Path $tempFolder -Recurse -Force
                }
                catch {
                    Write-Debug 'Failed to remove temporary folder'
                }
            }
        }
    }
    end {
    }
}
