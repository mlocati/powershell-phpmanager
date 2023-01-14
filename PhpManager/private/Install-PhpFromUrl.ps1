function Install-PhpFromUrl() {
    <#
    .Synopsis
    Installs PHP, fetching its binary archive from an URL.

    .Parameter Url
    The URL where the binary archive can be downloaded from.

    .Parameter Path
    The path where the archive should be extracted to.

    .Parameter PhpVersion
    The instance of PphVersion we are going to install.

    .Parameter InstallVCRedist
    Install the Visual C++ Redistributables if they are missing?
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The URL where the binary archive can be downloaded from')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Url,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = 'The path where the archive should be extracted to')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [Parameter(Mandatory = $true, Position = 2, HelpMessage = 'The instance of PphVersion we are going to install')]
        [ValidateNotNull()]
        [PhpVersionDownloadable] $PhpVersion,
        [Parameter(Mandatory = $true, Position = 3, HelpMessage = 'Install the Visual C++ Redistributables if they are missing?')]
        [bool] $InstallVCRedist
    )
    begin {
    }
    process {
        $temporaryFile, $keepTemporaryFile = Get-FileFromUrlOrCache -Url $Url
        try {
            $temporaryDirectory = New-TempDirectory
            try {
                Write-Verbose "Extracting $temporaryFile to temporary directory"
                try {
                    Expand-ArchiveWith7Zip -ArchivePath $temporaryFile -DestinationPath $temporaryDirectory -Overwrite
                } catch {
                    $keepTemporaryFile = $false
                    throw
                }
                $exePath = Join-Path -Path $temporaryDirectory -ChildPath php.exe
                if (-Not(Test-Path -Path $exePath -PathType Leaf)) {
                    throw "Unable to find php.exe in the downloaded archive"
                }
                try {
                    $exeOutput = & $exePath @('-n', '-v') 2>&1 | Out-String
                } catch {
                    $exeOutput = $_.Exception.Message
                }
                $exeExitCode = $LASTEXITCODE
                if ($exeExitCode -eq $Script:STATUS_DLL_NOT_FOUND -or $exeExitCode -eq $Script:ENTRYPOINT_NOT_FOUND  -or $exeExitCode -eq $Script:STATUS_INVALID_IMAGE_FORMAT -or $exeOutput -match 'vcruntime.*is not compatible with this PHP build') {
                    switch ($PhpVersion.VCVersion) {
                        6 { $redistName = '6' } # PHP 5.2, PHP 5.3
                        7 { $redistName = '2002' }
                        7.1 { $redistName = '2003' }
                        8 { $redistName = '2005' }
                        9 { $redistName = '2008' } # PHP 5.4
                        10 { $redistName = '2010' }
                        11 { $redistName = '2012' } # PHP 5.5, PHP 5.6
                        12 { $redistName = '2013' }
                        14 { $redistName = '2015' } # PHP 7.0, PHP 7.1
                        15 { $redistName = '2017' } # PHP 7.2, PHP 7.3
                        16 { $redistName = '2019' } # PHP 7.4
                        default {
                            throw ('The Visual C++ ' + $PhpVersion.VCVersion + ' Redistributable seems to be missing: you have to install it manually (we can''t recognize its version)')
                        }
                    }
                    if (-Not($InstallVCRedist)) {
                        throw "The Visual C++ $redistName Redistributable seems to be missing: you have to install it manually"
                    }
                    $vcRedistModule = Get-Module -Name VcRedist
                    if (-Not($vcRedistModule)) {
                        $vcRedistModule = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'VcRedist' }
                        if (-Not($vcRedistModule)) {
                            throw "The Visual C++ $redistName Redistributable seems to be missing: you have to manually install it (if you install the VcRedist PowerShell module we could try to install it automatically)"
                        }
                    }
                    $vcListKind = 'Supported'
                    $vcList = Get-VcList -Export $vcListKind | Where-Object { $_.Release -eq $redistName -and $_.Architecture -eq $PhpVersion.Architecture }
                    if (-Not($vcList)) {
                        $vcListKind = 'All'
                        $vcList = Get-VcList -Export $vcListKind | Where-Object { $_.Release -eq $redistName -and $_.Architecture -eq $PhpVersion.Architecture }
                        if (-Not($vcList)) {
                            throw "The Visual C++ $redistName Redistributable seems to be missing: you have to manually install it (the VcRedist PowerShell module doesn't support it)"
                        }
                    }
                    Write-Verbose "Downloading the Visual C++ $redistName Redistributable (it's required by this version of PHP)"
                    $temporaryDirectory2 = New-TempDirectory
                    try {
                        if ($vcRedistModule.Version -lt '2.0') {
                            $vcRedistCommand = 'Get-VcRedist'
                        } else {
                            $vcRedistCommand = 'Save-VcRedist'
                        }
                        $vcList | & $vcRedistCommand -Path $temporaryDirectory2
                        Write-Verbose "Installing the Visual C++ $redistName Redistributable"
                        $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                        if ($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
                            $vcList | Install-VcRedist -Path $temporaryDirectory2
                        } else {
                            $exeCommand = "Get-VcList -Export $vcListKind"
                            $exeCommand += " | Where-Object { `$_.Release -eq '$redistName' -and `$_.Architecture -eq '" + $PhpVersion.Architecture + "' }"
                            $exeCommand += " | Install-VcRedist -Path '" + ($temporaryDirectory2 -replace "'", "''") + "'"
                            Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs -Wait
                        }
                    } finally {
                        try {
                            Remove-Item -Path $temporaryDirectory2 -Recurse -Force
                        } catch {
                            Write-Debug 'Failed to remove temporary folder'
                        }
                    }
                } elseif ($exeExitCode -ne 0) {
                    throw "Running PHP resulted in the following error:`n$exeOutput"
                }
            } finally {
                try {
                    Remove-Item -Path $temporaryDirectory -Recurse -Force
                } catch {
                    Write-Debug 'Failed to remove temporary folder'
                }
            }
            Write-Verbose "Extracting $temporaryFile to destination directory"
            Expand-ArchiveWith7Zip -ArchivePath $temporaryFile -DestinationPath $Path -Overwrite
            try {
                $mostRecentApacheFile = $null
                $mostRecentApacheFileVersion = $null
                $apacheDlls = @(Get-ChildItem -LiteralPath $Path -Filter 'php*apache*.dll')
                $apacheDlls = $apacheDlls | Where-Object { $_.BaseName -match '^php(\d+(_\d+)*)apache(\d+(_\d+)*)$' }
                foreach ($apacheDll in $apacheDlls) {
                    $match = $apacheDll.BaseName | Select-String -Pattern '^php(\d+(?:_\d+)*)apache(\d+(?:_\d+)*)$'
                    if ($match) {
                        $apacheFile = [System.IO.Path]::Combine($Path, 'Apache' + $match.Matches[0].Groups[2].Value + '.conf')
                        $apacheFileVersion = [System.Version](($match.Matches[0].Groups[2].Value -replace '_', '.') + '.0.0')
                        if (-Not(Test-Path -LiteralPath $apacheFile)) {
                            if ($match.Matches[0].Groups[1].Value -match '^[1-7]($|_)') {
                                $moduleName = 'php' + $match.Matches[0].Groups[1].Value + '_module'
                            } else {
                                $moduleName = 'php_module'
                            }
                            $fullName = $apacheDll.FullName
                            Set-Content -LiteralPath $apacheFile -Value "LoadModule $moduleName ""$fullName"""
                        }
                        if ($null -eq $mostRecentApacheFile -or $mostRecentApacheFileVersion -lt $apacheFileVersion) {
                            $mostRecentApacheFile = $apacheFile
                            $mostRecentApacheFileVersion = $apacheFileVersion
                        }
                    }
                }
                $genericApacheFile = [System.IO.Path]::Combine($Path, 'Apache.conf')
                if ($null -ne $mostRecentApacheFile -and -Not(Test-Path -LiteralPath $genericApacheFile)) {
                    Copy-Item -Path $mostRecentApacheFile -Destination $genericApacheFile
                }
            } catch {
                Write-Debug 'Failed to configure the Apache.conf file'
            }
        } finally {
            if (-Not($keepTemporaryFile)) {
                try {
                    Remove-Item -Path $temporaryFile
                } catch {
                    Write-Debug 'Failed to remove temporary file'
                }
            }
        }
    }
    end {
    }
}
