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
    Param(
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
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = Get-OnePhpVersionFromEnvironment
        } Else {
            $phpVersion = Get-PhpVersionFromPath -Path $Path
        }
        $tempFolder = $null
        Try {
            If (Test-Path -Path $Extension -PathType Leaf) {
                If ($null -ne $Version -and $Version -ne '') {
                    Throw 'You can''t specify the -Version argument if you specify an existing file with the -Extension argument'
                }
                If ($null -ne $MinimumStability -and $MinimumStability -ne '') {
                    Throw 'You can''t specify the -MinimumStability argument if you specify an existing file with the -Extension argument'
                }
                $dllPath = [System.IO.Path]::GetFullPath($Extension)
            } Else {
                If ($null -eq $MinimumStability -or $MinimumStability -eq '') {
                    $MinimumStability = $Script:PEARSTATE_STABLE
                }
                $peclPackages = @(Get-PeclAvailablePackage)
                $foundPeclPackages = @($peclPackages | Where-Object {$_ -eq $Extension})
                If ($foundPeclPackages.Count -ne 1) {
                    $foundPeclPackages = @($peclPackages | Where-Object {$_ -like "*$Extension*"})
                    If ($foundPeclPackages.Count -eq 0) {
                        Throw "No PECL extensions found containing '$Extension'"
                    }
                    If ($foundPeclPackages.Count -ne 1) {
                        Throw ("Multiple PECL extensions found containing '$Extension':`n - " + [String]::Join("`n - ", $foundPeclPackages))
                    }
                }
                $peclPackageHandle = $foundPeclPackages[0]
                $peclPackageVersions = @(Get-PeclPackageVersion -Handle $peclPackageHandle -Version $Version -MinimumStability $MinimumStability)
                If ($peclPackageVersions.Count -eq 0) {
                    If ($null -eq $Version -or $Version -eq '') {
                        Throw "The PECL package $peclPackageHandle does not have any version with a $MinimumStability minimum stability"
                    }
                    Throw "The PECL package $peclPackageHandle does not have any $Version version with a $MinimumStability minimum stability"
                }
                $foundDll = $null
                ForEach ($peclPackageVersion in $peclPackageVersions) {
                    $dlls = @(Get-PeclDll -Handle $peclPackageHandle -Version $peclPackageVersion -PhpVersion $phpVersion -MinimumStability $MinimumStability)
                    If ($dlls.Count -eq 0) {
                        Write-Verbose ("No Windows DLLs found for PECL package {0} {1} compatible with {2}" -f $peclPackageHandle, $peclPackageVersion, $phpVersion.DisplayName)
                    } Else {
                        $foundDll = $dlls[0]
                        break
                    }
                }
                If ($null -eq $foundDll) {
                    Throw "No compatible Windows DLL found for PECL package $peclPackageHandle with a $MinimumStability minimum stability"
                }
                Write-Output ("Downloading PECL package {0} {1} from {2}" -f $peclPackageHandle, $foundDll.Version, $foundDll.Url)
                $zip, $keepZip = Get-FileFromUrlOrCache -Url $foundDll.Url
                Try {
                    $tempFolder = New-TempDirectory
                    Expand-Archive -LiteralPath $zip -DestinationPath $tempFolder
                    $phpDlls = @(Get-ChildItem -Path $tempFolder\php_*.dll -File -Depth 0)
                    If ($phpDlls.Count -eq 0) {
                        $phpDlls = @(Get-ChildItem -Path $tempFolder\php_*.dll -File -Depth 1)
                    }
                    If ($phpDlls.Count -eq 0) {
                        Throw ("No PHP DLL found in archive downloaded from {0}" -f $foundDll.Url)
                    }
                    If ($phpDlls.Count -ne 1) {
                        Throw ("Multiple PHP DLL found in archive downloaded from {0}" -f $foundDll.Url)
                    }
                    $dllPath = $phpDlls[0].FullName
                }
                Catch {
                    $keepZip = $false
                    Throw
                }
                Finally {
                    If (-Not($keepZip)) {
                        Try {
                            Remove-Item -Path $zip -Force
                        }
                        Catch {
                            Write-Debug 'Failed to remove temporary zip file'
                        }
                    }
                }
            }
            $newExtension = Get-PhpExtensionDetail -PhpVersion $phpVersion -Path $dllPath
            $oldExtension = Get-PhpExtension -Path $phpVersion.ExecutablePath | Where-Object {$_.Handle -eq $newExtension.Handle}
            If ($null -ne $oldExtension) {
                If ($oldExtension.Type -eq $Script:EXTENSIONTYPE_BUILTIN) {
                    Write-Output ("'{0}' is a builtin extension" -f $oldExtension.Name)
                }
                Write-Output ("Upgrading extension '{0}' from version {1} to version {2}" -f $oldExtension.Name, $oldExtension.Version, $newExtension.Version)
                Move-Item -Path $dllPath -Destination $oldExtension.Filename -Force
                If ($oldExtension.State -eq $Script:EXTENSIONSTATE_DISABLED -and -Not($DontEnable)) {
                    Enable-PhpExtension -Extension $oldExtension.Name -Path $phpVersion.ExecutablePath
                }
            } Else {
                Write-Output ("Installing new extension '{0}' version {1}" -f $newExtension.Name, $newExtension.Version)
                Install-PhpExtensionPrerequisite -PhpVersion $phpVersion -Extension $newExtension
                $newExtensionFilename = [System.IO.Path]::Combine($phpVersion.ExtensionsPath, [System.IO.Path]::GetFileName($dllPath))
                Move-Item -Path $dllPath -Destination $newExtensionFilename
                If (-Not($DontEnable)) {
                    Enable-PhpExtension -Extension $newExtension.Name -Path $phpVersion.ExecutablePath
                }
            }
        }
        Finally {
            If ($null -ne $tempFolder) {
                Try {
                    Remove-Item -Path $tempFolder -Recurse -Force
                }
                Catch {
                    Write-Debug 'Failed to remove temporary folder'
                }
            }
        }
    }
    End {
    }
}
