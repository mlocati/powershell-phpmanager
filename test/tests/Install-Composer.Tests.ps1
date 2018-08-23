Describe 'Install-Composer' {
    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }
    $phpPath = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid
    $composerPath = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid
    $composerBat = Join-Path -Path $composerPath -ChildPath 'composer.bat'
    It 'should install Composer' {
        if (Test-Path -LiteralPath $phpPath) {
            Remove-Item -LiteralPath $phpPath -Recurse -Force
        }
        if (Test-Path -LiteralPath $composerPath) {
            Remove-Item -LiteralPath $composerPath -Recurse -Force
        }
        try {
            Install-Php -Version 7.1.0 -Architecture x64 -ThreadSafe $true -Path $phpPath
            Enable-PhpExtension -Extension curl,openssl -Path $phpPath
            Update-PhpCAInfo -Path $phpPath
            Install-Composer -Path $composerPath -PhpPath $phpPath -Scope User -NoAddToPath -NoCache
            $composerBat | Should -Exist
            & $composerBat @('--version')
            $LASTEXITCODE | Should -Be 0
        } finally {
            try {
                if (Test-Path -LiteralPath $composerPath) {
                    Remove-Item -LiteralPath $composerPath -Recurse -Force
                }
            } catch {
            }
            try {
                if (Test-Path -LiteralPath $phpPath) {
                    Remove-Item -LiteralPath $phpPath -Recurse -Force
                }
            } catch {
            }
        }
    }
}
