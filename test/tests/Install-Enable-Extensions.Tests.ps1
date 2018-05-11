Describe 'Install-Enable-Extensions' {
    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }

    $testCases = @(
        @{version = '7.1'; path = (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid)}
    )
    <# I don't know how to setup the VCRedist 2017 on nanoserver: let's skip PHP 7.2 on it #>
    if (Join-Path -Path $Env:windir -ChildPath System32\imm32.dll | Test-Path -PathType Leaf) {
        $testCases += @{version = '7.2'; path = (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid)}
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
