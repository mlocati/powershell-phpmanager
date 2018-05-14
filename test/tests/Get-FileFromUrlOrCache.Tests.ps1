Describe 'Get-FileFromUrlOrCache' {

    Context 'Context #1' {
        It 'should download when cache is disabled' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return '' }
            Mock -ModuleName PhpManager Get-TemporaryFileWithExtension { return 'C:\Path\To\LocalFile.zip' } -ParameterFilter { $Extension -eq '.zip'}
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/remote.file.zip'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Get-TemporaryFileWithExtension
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 1 -Exactly
            $localFile | Should -BeExactly 'C:\Path\To\LocalFile.zip'
            $fromCache | Should -BeExactly $False
        }
    }

    Context 'Context #2' {
        It 'should download when cache is enabled but file is missing' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $false } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache\filename.zip' }
            Mock -ModuleName PhpManager Get-TemporaryFileWithExtension { return 'C:\Path\To\TemporaryFile.zip' } -ParameterFilter { $Extension -eq '.zip'}
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            Mock -ModuleName PhpManager Move-Item {} -ParameterFilter { $LiteralPath -eq 'C:\Path\To\TemporaryFile.zip' -and $Destination -eq 'C:\Path\To\Cache\filename.zip' }
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/filename.zip'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Get-TemporaryFileWithExtension
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 1 -Exactly
            Assert-MockCalled -ModuleName PhpManager Move-Item
            $localFile | Should -BeExactly 'C:\Path\To\Cache\filename.zip'
            $fromCache | Should -BeExactly $true
        }
    }

    Context 'Context #3' {
        It 'should not download a cached file' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache\filename.zip' }
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/filename.zip'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 0 -Exactly
            $localFile | Should -BeExactly 'C:\Path\To\Cache\filename.zip'
            $fromCache | Should -BeExactly $true
        }
    }

    Context 'Context #4' {
        It 'should download when cache is disabled - with specific name' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return '' }
            Mock -ModuleName PhpManager Get-TemporaryFileWithExtension { return 'C:\Path\To\LocalFile.xz' } -ParameterFilter { $Extension -eq '.xz'}
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/url' -CachedFileName 'NewName.xz'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Get-TemporaryFileWithExtension
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 1 -Exactly
            $localFile | Should -BeExactly 'C:\Path\To\LocalFile.xz'
            $fromCache | Should -BeExactly $False
        }
    }

    Context 'Context #5' {
        It 'should download when cache is enabled but file is missing - with specific name' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $false } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache\NewName.xz' }
            Mock -ModuleName PhpManager Get-TemporaryFileWithExtension { return 'C:\Path\To\TemporaryFile.xz' } -ParameterFilter { $Extension -eq '.xz'}
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            Mock -ModuleName PhpManager Move-Item {} -ParameterFilter { $LiteralPath -eq 'C:\Path\To\TemporaryFile.xz' -and $Destination -eq 'C:\Path\To\Cache\NewName.xz' }
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/url' -CachedFileName 'NewName.xz'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Get-TemporaryFileWithExtension
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 1 -Exactly
            Assert-MockCalled -ModuleName PhpManager Move-Item
            $localFile | Should -BeExactly 'C:\Path\To\Cache\NewName.xz'
            $fromCache | Should -BeExactly $true
        }
    }

    Context 'Context #6' {
        It 'should not download a cached file - with specific name' {
            Mock -ModuleName PhpManager Get-PhpDownloadCache { return 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache' }
            Mock -ModuleName PhpManager Test-Path { return $true } -ParameterFilter { $LiteralPath -eq 'C:\Path\To\Cache\NewName.xz' }
            Mock -ModuleName PhpManager Invoke-WebRequest {}
            $localFile, $fromCache = Get-FileFromUrlOrCache -Url 'https://www.example.com/sample/url' -CachedFileName 'NewName.xz'
            Assert-MockCalled -ModuleName PhpManager Get-PhpDownloadCache
            Assert-MockCalled -ModuleName PhpManager Invoke-WebRequest -Times 0 -Exactly
            $localFile | Should -BeExactly 'C:\Path\To\Cache\NewName.xz'
            $fromCache | Should -BeExactly $true
        }
    }
}
