Describe 'Get-PhpVersionFromUrl' {
    It 'parses a release without build number' {
        $v = Get-PhpVersionFromUrl -Url 'https://downloads.php.net/~windows/releases/php-8.5.12-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $v.FullVersion | Should -BeExactly '8.5.12'
        $v.Build | Should -Be 0
        $v.ThreadSafe | Should -BeFalse
        $v.VCVersion | Should -Be 17
        $v.Architecture | Should -BeExactly 'x64'
        $v.DisplayName | Should -BeExactly 'PHP 8.5.12 x64 (64-bit) Non-Thread-Safe'
    }
    It 'parses a release with build number' {
        $v = Get-PhpVersionFromUrl -Url 'https://downloads.php.net/~windows/releases/php-8.5.12-1-Win32-vs17-x86.zip' -ReleaseState Release
        $v.FullVersion | Should -BeExactly '8.5.12'
        $v.Build | Should -Be 1
        $v.ThreadSafe | Should -BeTrue
        $v.Architecture | Should -BeExactly 'x86'
        $v.DisplayName | Should -BeExactly 'PHP 8.5.12-1 x86 (32-bit) Thread-Safe'
    }
    It 'parses a release candidate with build number' {
        $v = Get-PhpVersionFromUrl -Url 'php-8.6.0RC4-2-nts-Win32-vs18-x64.zip' -ReleaseState QA
        $v.FullVersion | Should -BeExactly '8.6.0rc4'
        $v.Build | Should -Be 2
    }
    It 'prefers higher build numbers of the same version' {
        $v0 = Get-PhpVersionFromUrl -Url 'php-8.5.12-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $v1 = Get-PhpVersionFromUrl -Url 'php-8.5.12-1-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $v2 = Get-PhpVersionFromUrl -Url 'php-8.5.12-2-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $next = Get-PhpVersionFromUrl -Url 'php-8.5.13-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $v1.CompareTo($v0) | Should -BeGreaterThan 0
        $v2.CompareTo($v1) | Should -BeGreaterThan 0
        $v0.CompareTo($v1) | Should -BeLessThan 0
        $next.CompareTo($v2) | Should -BeGreaterThan 0
        ($v0 -lt $v1) | Should -BeTrue
    }
    It 'ignores the build number when it is unknown' {
        $v1 = Get-PhpVersionFromUrl -Url 'php-8.5.12-1-nts-Win32-vs17-x64.zip' -ReleaseState Release
        $unknown = & (Get-Module PhpManager) { [PhpVersion]::new(@{Version = '8.5.12'; Architecture = 'x64'; ThreadSafe = $false; VCVersion = 17}) }
        $unknown.Build | Should -BeNullOrEmpty
        $v1.CompareTo($unknown) | Should -Be 0
        $unknown.CompareTo($v1) | Should -Be 0
    }
}
