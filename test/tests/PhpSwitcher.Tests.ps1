Describe 'PhpSwitcher' {
    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }

    $alias = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid
    if (Test-Path -LiteralPath $alias) {
        Remove-Item -LiteralPath $alias -Recurse -Force
    }
    $Global:phpManagerTest_phpSwitcherData = New-Object -TypeName PSCustomObject
    $Global:phpManagerTest_phpSwitcherData | Add-Member -MemberType NoteProperty -Name Scope -Value 'CurrentUser'
    $Global:phpManagerTest_phpSwitcherData | Add-Member -MemberType NoteProperty -Name Alias -Value $alias
    $Global:phpManagerTest_phpSwitcherData | Add-Member -MemberType NoteProperty -Name Targets -Value (New-Object -TypeName PSCustomObject)
    $installations = @(
        @{version = '7.0'; path = (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid)}
        @{version = '7.1'; path = (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath (New-Guid).Guid)}
    )
    foreach ($installation in $installations) {
        if (Test-Path -LiteralPath $installation.path) {
            Remove-Item -LiteralPath $installation.path -Recurse -Force
        }
        $Global:phpManagerTest_phpSwitcherData.Targets | Add-Member -MemberType NoteProperty -Name $installation.version -Value $installation.path
    }
    Mock -ModuleName PhpManager Get-PhpManagerConfigurationKey { return $Global:phpManagerTest_phpSwitcherData } -ParameterFilter { $Key -eq 'PHP_SWITCHER' }
    Mock -ModuleName PhpManager Set-PhpManagerConfigurationKey {  } -ParameterFilter { $Key -eq 'PHP_SWITCHER' }
    try {
        foreach ($installation in $installations) {
            Install-Php -Version $installation.version -Architecture x64 -ThreadSafe $true -Path $installation.path
        }
        It 'should be an instance of PhpSwitcher' {
            $phpSwitcher = Get-PhpSwitcher
            Assert-MockCalled -ModuleName PhpManager Get-PhpManagerConfigurationKey -Scope It -Times 1 -Exactly
            $phpSwitcher | Should -Not -BeNullOrEmpty
            $phpSwitcher.GetType().FullName | Should -BeExactly 'PhpSwitcher'
            $phpSwitcher.Scope | Should -BeExactly 'CurrentUser'
            $phpSwitcher.Alias | Should -BeExactly $alias
            $phpSwitcher.Targets.Keys | Should -HaveCount $installations.Count
            foreach ($installation in $installations) {
                $phpSwitcher.Targets.Keys | Should -Contain $installation.version
            }
        }
        It 'should switch PHP version and remove the alias when removed' {
            $alias | Should -Not -Exist
            foreach ($installation in $installations) {
                Switch-Php -Name $installation.version
                $alias | Should -Exist
                $phpVersion = Get-Php -Path $alias
                $phpVersion | Should -Not -BeNullOrEmpty
                $phpVersion.Version | Should -BeLike "$($installation.version).*"
            }
            Switch-Php -Name $installations[0].version
            $alias | Should -Exist
            { Remove-PhpFromSwitcher -Name $installations[0].version } | Should -Throw
            Assert-MockCalled -ModuleName PhpManager Set-PhpManagerConfigurationKey -Scope It -Times 0 -Exactly
            Remove-PhpFromSwitcher -Name $installations[0].version -Force
            Assert-MockCalled -ModuleName PhpManager Set-PhpManagerConfigurationKey -Scope It -Times 1 -Exactly
            $alias | Should -Exist
            Switch-Php -Name $installations[1].version
            $alias | Should -Exist
            Remove-PhpSwitcher
            Assert-MockCalled -ModuleName PhpManager Set-PhpManagerConfigurationKey -Scope It -Times 2 -Exactly
            $alias | Should -Not -Exist
        }
    } finally {
        Remove-Variable -Name phpManagerTest_phpSwitcherData -Scope Global
        if (Test-Path -LiteralPath $alias) {
            Remove-Item -LiteralPath $alias -Recurse -Force
        }
        foreach ($installation in $installations) {
            if (Test-Path -LiteralPath $installation.path) {
                Remove-Item -LiteralPath $installation.path -Recurse -Force
            }
        }
    }
}
