Describe 'Get-PeclArchiveUrl' {
    $phpVersion = Get-PhpVersionFromUrl -Url http://www.example.com/php-7.2.5-nts-Win32-VC15-x64.zip -ReleaseState Release
    It 'returns an empty string if the package handle is not recognized' {
        Get-PeclArchiveUrl -PackageHandle ThisIsAnInvalidNameOfAPECLPackage -PackageVersion 1.0.0 -PhpVersion $phpVersion | Should -BeExactly ''
    }
    It 'returns an empty string if the package version is not found' {
        Get-PeclArchiveUrl -PackageHandle xdebug -PackageVersion 99.99.99 -PhpVersion $phpVersion | Should -BeExactly ''
    }
    It 'returns the latest xdebug ZIP url for PHP 7.2' {
        Get-PeclArchiveUrl -PackageHandle xdebug -PackageVersion 2.6.0 -PhpVersion $phpVersion | Should -BeLike '*.zip'
    }
    It 'returns an empty string for latest imagick ZIP url for PHP 7.2 (minimum stability: default)' {
        Get-PeclArchiveUrl -PackageHandle imagick -PackageVersion 3.4.3 -PhpVersion $phpVersion | Should -BeExactly ''
    }
    It 'returns the latest imagick ZIP url for PHP 7.2 (minimum stability: snapshot)' {
        Get-PeclArchiveUrl -PackageHandle imagick -PackageVersion 3.4.3 -PhpVersion $phpVersion -Stability snapshot | Should -BeLike '*.zip'
    }
}
