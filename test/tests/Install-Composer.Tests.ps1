Describe 'Install-Composer' {
    BeforeAll {
        function GetInstalledComposerVersion()
        {
            param (
                [Parameter(Mandatory = $true, Position = 0)]
                [string] $composerBatPath
            )
            $output = & $composerBat @('--version')
            if ($LASTEXITCODE -ne 0) {
                return "Failed to launch composer. Its output is`n$output"
            }
            $match = $output | Select-String -Pattern 'Composer\s+(?:v(?:er(?:s(?:ion)?)?)?\.?\s*)?(\d\S*)'
            if (-not($match)) {
                return "Failed to detect Composer version from`n$output"
            }
            return $match.Matches.Groups[1].Value
        }
    }
    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }
    $phpPath = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid
    $composerPath = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid
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
            GetInstalledComposerVersion($composerBat) | Should -Match '^([2-9]\d*|1\d+)\.'
            Install-Composer -Path $composerPath -PhpPath $phpPath -Scope User -NoAddToPath -NoCache -Version 1
            GetInstalledComposerVersion($composerBat) | Should -Match '^1\.'
            Install-Composer -Path $composerPath -PhpPath $phpPath -Scope User -NoAddToPath -NoCache -Version 2
            GetInstalledComposerVersion($composerBat) | Should -Match '^2\.'
            Install-Composer -Path $composerPath -PhpPath $phpPath -Scope User -NoAddToPath -NoCache -Version '1.10.15'
            GetInstalledComposerVersion($composerBat) | Should -Be '1.10.15'
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
