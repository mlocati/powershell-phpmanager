Describe 'Install-Enable-Extensions' {
    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }

    $testCases = @(
        @{version = '7.1'; path = (Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid)}
    )
    <# I don't know how to setup the VCRedist 2017 on nanoserver: let's skip PHP 7.2 on it #>
    if (Join-Path -Path $Env:windir -ChildPath System32\imm32.dll | Test-Path -PathType Leaf) {
        $testCases += @{version = '7.2'; path = (Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid)}
    }
    foreach ($testCase in $testCases) {
        if (Test-Path -LiteralPath $testCase.path) {
            Remove-Item -LiteralPath $testCase.path -Recurse -Force
        }
    }
    try {
        foreach ($testCase in $testCases) {
            Install-Php -Version $testCase.version -Architecture x64 -ThreadSafe $true -Path $testCase.path
        }
        It -Name 'should enable/disable GD and mbstring on PHP <version>' -TestCases $testCases {
            param ($path)
            Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'mbstring' -or $_.Handle -eq 'gd'} | Should -HaveCount 2
            Disable-PhpExtension -Extension mbstring,gd -Path $path
            Enable-PhpExtension -Extension mbstring,gd -Path $path
            Get-PhpExtension -Path $path | Where-Object {$_.State -eq 'Enabled' -and $_.Type -eq 'Php' } | Where-Object { $_.Handle -eq 'mbstring' -or $_.Handle -eq 'gd'} | Should -HaveCount 2
            Disable-PhpExtension -Extension mbstring,gd -Path $path
            Get-PhpExtension -Path $path | Where-Object {$_.State -eq 'Enabled' } | Where-Object { $_.Handle -eq 'mbstring' -or $_.Handle -eq 'gd'} | Should -HaveCount 0
        }
        It -Name 'should download and install xdebug on PHP <version>' -TestCases $testCases {
            param ($path)
            Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'xdebug' } | Should -HaveCount 0
            Install-PhpExtension -Extension xdebug -Path $path
            $xdebug = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'xdebug' }
            $xdebug | Should -HaveCount 1
            $xdebug.Type | Should -BeExactly 'Zend'
            $xdebug.State | Should -BeExactly 'Enabled'
            Disable-PhpExtension -Extension xdebug -Path $path
            $xdebug = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'xdebug' }
            $xdebug | Should -HaveCount 1
            $xdebug.Type | Should -BeExactly 'Zend'
            $xdebug.State | Should -BeExactly 'Disabled'
        }
        It -Name 'should download and install imagick on PHP <version>' -TestCases $testCases {
            param ($path, $version)
            Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'imagick' } | Should -HaveCount 0
            if ($version -eq '7.2') {
                Install-PhpExtension -Extension imagick -Path $path -MinimumStability snapshot
            } else {
                Install-PhpExtension -Extension imagick -Path $path
            }
            $imagick = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'imagick' }
            $imagick | Should -HaveCount 1
            $imagick.Type | Should -BeExactly 'Php'
            $imagick.State | Should -BeExactly 'Enabled'
            Disable-PhpExtension -Extension imagick -Path $path
            $imagick = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'imagick' }
            $imagick | Should -HaveCount 1
            $imagick.Type | Should -BeExactly 'Php'
            $imagick.State | Should -BeExactly 'Disabled'
        }
        It -Name 'should download and install yaml on PHP <version>' -TestCases $testCases {
            param ($path, $version)
            Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'yaml' } | Should -HaveCount 0
            Install-PhpExtension -Extension yaml -Path $path
            $yaml = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'yaml' }
            $yaml | Should -HaveCount 1
            $yaml.Type | Should -BeExactly 'Php'
            $yaml.State | Should -BeExactly 'Enabled'
        }
        It -Name 'should download and install couchbase on PHP <version>' -TestCases $testCases {
            param ($path, $version)
            if (-not(Join-Path -Path $Env:windir -ChildPath System32\msvcp140.dll | Test-Path -PathType Leaf)) {
                if (-not(Join-Path -Path $Env:windir -ChildPath System32\msvcp160.dll | Test-Path -PathType Leaf)) {
                    Set-ItResult -Skipped -Because 'Missing some required system DLLs'
                }
            }
            Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'couchbase' } | Should -HaveCount 0
            Install-PhpExtension -Extension couchbase -Path $path
            $couchbase = Get-PhpExtension -Path $path | Where-Object { $_.Handle -eq 'couchbase' }
            $couchbase | Should -HaveCount 1
            $couchbase.Type | Should -BeExactly 'Php'
            $couchbase.State | Should -BeExactly 'Enabled'
        }
        It -Name 'should handle multiple extension versions' {
            $phpPath = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid
            Install-Php -Version 7.1 -Architecture x64 -ThreadSafe $true -Path $phpPath
            $phpVersion = Get-Php -Path $phpPath
            try {
                Install-PhpExtension -Path $phpPath -Extension xdebug -Version 2.6 -DontEnable
                Move-Item -LiteralPath (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug.dll') -Destination (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.6')
                Install-PhpExtension -Path $phpPath -Extension xdebug -Version 2.7 -MinimumStability alpha -DontEnable
                Move-Item -LiteralPath (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug.dll') -Destination (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.7')
                Move-Item -LiteralPath (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.6') -Destination (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.6.dll')
                Move-Item -LiteralPath (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.7') -Destination (Join-Path -Path $phpVersion.ExtensionsPath -ChildPath 'php_xdebug-2.7.dll')
                { Enable-PhpExtension -Path $phpPath -Extension xdebug } | Should -Throw
                { Enable-PhpExtension -Path $phpPath -Extension 'xdebug:2.6' } | Should -Not -Throw
                Disable-PhpExtension -Path $phpPath -Extension xdebug
                { Enable-PhpExtension -Path $phpPath -Extension 'xdebug:2.7' } | Should -Not -Throw
            } finally {
                try {
                    Remove-Item -LiteralPath $phpPath -Recurse
                } catch {
                }
            }
        }
    } finally {
        foreach ($testCase in $testCases) {
            if (Test-Path -LiteralPath $testCase.path) {
                try {
                    Remove-Item -LiteralPath $testCase.path -Recurse
                } catch {
                }
            }
        }
    }
}
