Describe 'Install-Get-Update-Uninstall-Php' {

    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }
    $isNanoServer = (Get-ComputerInfo -Property WindowsInstallationType).WindowsInstallationType -eq 'Nano Server'
    $phpPath = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid
    It 'should install/get/update/remove PHP' {
        if (Test-Path -LiteralPath $phpPath) {
            Remove-Item -LiteralPath $phpPath -Recurse -Force
        }
        try {
            Install-Php -Version 7.1.0 -Architecture x64 -ThreadSafe $true -Path $phpPath
            $initialPhpVersion = Get-Php -Path $phpPath
            $initialPhpVersion | Should -Not -BeNullOrEmpty
            $initialPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $initialPhpVersion.Version | Should -BeOfType [string]
            $initialPhpVersion.Version | Should -BeExactly '7.1.0'
            $initialPhpVersion.MajorMinorVersion | Should -BeExactly '7.1'
            $initialPhpVersion.ComparableVersion | Should -BeOfType [version]
            $initialPhpVersion.UnstabilityLevel | Should -BeNullOrEmpty
            $initialPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $initialPhpVersion.FullVersion | Should -BeExactly $initialPhpVersion.Version
            $initialPhpVersion.DisplayName | Should -BeLike "*$($initialPhpVersion.Version)*"
            $initialPhpVersion.Architecture | Should -BeExactly 'x64'
            $initialPhpVersion.ThreadSafe | Should -BeExactly $true
            $initialPhpVersion.VCVersion | Should -BeOfType [int]
            $initialPhpVersion.Folder | Should -BeExactly $phpPath
            $initialPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $initialPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $initialPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $initialPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Update-Php -Path $phpPath | Should -BeExactly $true
            $updatedPhpVersion = Get-Php -Path $phpPath
            $updatedPhpVersion | Should -Not -BeNullOrEmpty
            $updatedPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $updatedPhpVersion.Version | Should -BeOfType [string]
            $updatedPhpVersion.Version | Should -Match '^7\.1\.'
            $updatedPhpVersion.ComparableVersion | Should -BeOfType [version]
            $updatedPhpVersion.ComparableVersion | Should -BeGreaterThan $initialPhpVersion.ComparableVersion
            $updatedPhpVersion.UnstabilityLevel | Should -BeNullOrEmpty
            $updatedPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $updatedPhpVersion.FullVersion | Should -BeExactly $updatedPhpVersion.Version
            $updatedPhpVersion.DisplayName | Should -BeLike "*$($updatedPhpVersion.Version)*"
            $updatedPhpVersion.Architecture | Should -BeExactly $initialPhpVersion.Architecture
            $updatedPhpVersion.ThreadSafe | Should -BeExactly $initialPhpVersion.ThreadSafe
            $updatedPhpVersion.VCVersion | Should -BeExactly $initialPhpVersion.VCVersion
            $updatedPhpVersion.Folder | Should -BeExactly $phpPath
            $updatedPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $updatedPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $updatedPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $updatedPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Uninstall-Php -Path $phpPath
            $phpPath | Should -Not -Exist
        } finally {
            try {
                if (Test-Path -LiteralPath $phpPath) {
                    Remove-Item -LiteralPath $phpPath -Recurse -Force
                }
            } catch {
            }
        }
    }
    It 'should install/get/update/remove PHP 7.3-dev' {
        if ($isNanoServer) {
            Set-ItResult -Skipped -Because 'it does not seems possible to install the Visual C++ 2019 Redistributables on Windows Nano Server'
        }
        if (Test-Path -LiteralPath $phpPath) {
            Remove-Item -LiteralPath $phpPath -Recurse -Force
        }
        try {
            Install-Php -Version 7.3snapshot -Architecture x64 -ThreadSafe $true -Path $phpPath -InstallVC
            $initialPhpVersion = Get-Php -Path $phpPath
            $initialPhpVersion | Should -Not -BeNullOrEmpty
            $initialPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $initialPhpVersion.Version | Should -BeOfType [string]
            $initialPhpVersion.Version | Should -MatchExactly '^7\.3\.\d+$'
            $initialPhpVersion.MajorMinorVersion | Should -BeExactly '7.3'
            $initialPhpVersion.ComparableVersion | Should -BeOfType [version]
            $initialPhpVersion.UnstabilityLevel | Should -BeExactly 'snapshot'
            $initialPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $initialPhpVersion.FullVersion | Should -MatchExactly '^7\.3\.\d+-dev$'
            $initialPhpVersion.Architecture | Should -BeExactly 'x64'
            $initialPhpVersion.ThreadSafe | Should -BeExactly $true
            $initialPhpVersion.VCVersion | Should -BeOfType [int]
            $initialPhpVersion.Folder | Should -BeExactly $phpPath
            $initialPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $initialPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $initialPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $initialPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Update-Php -Path $phpPath | Should -BeExactly $true
            $updatedPhpVersion = Get-Php -Path $phpPath
            $updatedPhpVersion | Should -Not -BeNullOrEmpty
            $updatedPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $updatedPhpVersion.Version | Should -BeOfType [string]
            $initialPhpVersion.Version | Should -MatchExactly '^7\.3\.\d+$'
            $updatedPhpVersion.ComparableVersion | Should -BeOfType [version]
            $initialPhpVersion.UnstabilityLevel | Should -BeExactly 'snapshot'
            $updatedPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $initialPhpVersion.FullVersion | Should -MatchExactly '^7\.3\.\d+-dev$'
            $updatedPhpVersion.Architecture | Should -BeExactly $initialPhpVersion.Architecture
            $updatedPhpVersion.ThreadSafe | Should -BeExactly $initialPhpVersion.ThreadSafe
            $updatedPhpVersion.VCVersion | Should -BeExactly $initialPhpVersion.VCVersion
            $updatedPhpVersion.Folder | Should -BeExactly $phpPath
            $updatedPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $updatedPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $updatedPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $updatedPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Uninstall-Php -Path $phpPath
            $phpPath | Should -Not -Exist
        } finally {
            try {
                if (Test-Path -LiteralPath $phpPath) {
                    Remove-Item -LiteralPath $phpPath -Recurse -Force
                }
            } catch {
            }
        }
    }
    It 'should install/get/update/remove PHP master' {
        if ($isNanoServer) {
            Set-ItResult -Skipped -Because 'it does not seems possible to install the Visual C++ 2019 Redistributables on Windows Nano Server'
        }
        if (Test-Path -LiteralPath $phpPath) {
            Remove-Item -LiteralPath $phpPath -Recurse -Force
        }
        try {
            Install-Php -Version master -Architecture x64 -ThreadSafe $true -Path $phpPath -InstallVC
            $initialPhpVersion = Get-Php -Path $phpPath
            $initialPhpVersion | Should -Not -BeNullOrEmpty
            $initialPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $initialPhpVersion.Version | Should -BeOfType [string]
            $initialPhpVersion.Version | Should -MatchExactly '^\d+.\d+.\d+$'
            $initialPhpVersion.MajorMinorVersion | Should -MatchExactly '^\d+.\d+$'
            $initialPhpVersion.ComparableVersion | Should -BeOfType [version]
            $initialPhpVersion.UnstabilityLevel | Should -BeExactly 'snapshot'
            $initialPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $initialPhpVersion.FullVersion | Should -MatchExactly '^\d+.\d+.\d+-dev'
            $initialPhpVersion.Architecture | Should -BeExactly 'x64'
            $initialPhpVersion.ThreadSafe | Should -BeExactly $true
            $initialPhpVersion.VCVersion | Should -BeOfType [int]
            $initialPhpVersion.Folder | Should -BeExactly $phpPath
            $initialPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $initialPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $initialPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $initialPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Update-Php -Path $phpPath | Should -BeExactly $true
            $updatedPhpVersion = Get-Php -Path $phpPath
            $updatedPhpVersion | Should -Not -BeNullOrEmpty
            $updatedPhpVersion.GetType().FullName | Should -BeExactly 'PhpVersionInstalled'
            $updatedPhpVersion.Version | Should -BeOfType [string]
            $initialPhpVersion.Version | Should -MatchExactly '^\d+\.\d+.\d+$'
            $updatedPhpVersion.ComparableVersion | Should -BeOfType [version]
            $initialPhpVersion.UnstabilityLevel | Should -BeExactly 'snapshot'
            $updatedPhpVersion.UnstabilityVersion | Should -BeNullOrEmpty
            $initialPhpVersion.FullVersion | Should -MatchExactly '^\d+\.\d+\.\d+-dev$'
            $updatedPhpVersion.Architecture | Should -BeExactly $initialPhpVersion.Architecture
            $updatedPhpVersion.ThreadSafe | Should -BeExactly $initialPhpVersion.ThreadSafe
            $updatedPhpVersion.VCVersion | Should -BeExactly $initialPhpVersion.VCVersion
            $updatedPhpVersion.Folder | Should -BeExactly $phpPath
            $updatedPhpVersion.ActualFolder | Should -BeExactly $phpPath
            $updatedPhpVersion.ExecutablePath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.exe')
            $updatedPhpVersion.IniPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'php.ini')
            $updatedPhpVersion.ExtensionsPath | Should -BeExactly (Join-Path -Path $phpPath -ChildPath 'ext')
            Uninstall-Php -Path $phpPath
            $phpPath | Should -Not -Exist
        } finally {
            try {
                if (Test-Path -LiteralPath $phpPath) {
                    Remove-Item -LiteralPath $phpPath -Recurse -Force
                }
            } catch {
            }
        }
    }
    It 'should use the configured initial php.ini' {
        if (Test-Path -LiteralPath $phpPath) {
            Remove-Item -LiteralPath $phpPath -Recurse -Force
        }
        try {
            Install-Php -Version 7.1.0 -Architecture x64 -ThreadSafe $true -Path $phpPath
            Get-PhpIniKey -Key display_errors -Path $phpPath | Should -BeNullOrEmpty
            Uninstall-Php -Path $phpPath
            Install-Php -Version 7.1.0 -Architecture x64 -ThreadSafe $true -Path $phpPath -InitialPhpIni Development
            Get-PhpIniKey -Key display_errors -Path $phpPath | Should -BeExactly 'On'
            Uninstall-Php -Path $phpPath
            Install-Php -Version 7.1.0 -Architecture x64 -ThreadSafe $true -Path $phpPath -InitialPhpIni Production
            Get-PhpIniKey -Key display_errors -Path $phpPath | Should -BeExactly 'Off'
        } finally {
            try {
                if (Test-Path -LiteralPath $phpPath) {
                    Remove-Item -LiteralPath $phpPath -Recurse -Force
                }
            } catch {
            }
        }
    }
}
