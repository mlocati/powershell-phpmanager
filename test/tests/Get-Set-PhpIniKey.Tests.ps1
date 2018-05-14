Describe 'Get-Set-PhpIniKey' {

    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }
    $phpIniFolder = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs
    if (-Not(Test-Path -LiteralPath $phpIniFolder)) {
        New-Item -ItemType Directory -Path $phpIniFolder
    }
    $phpIniPath = Join-Path -Path $phpIniFolder -ChildPath 'php.ini'
    It 'should set/comment/uncomment/delete php.ini keys' {
        if (Test-Path -LiteralPath $phpIniPath) {
            Remove-Item -LiteralPath $phpIniPath -Force
        }
        try {
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeNullOrEmpty
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Value 'Ok, man'
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeExactly 'Ok, man'
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Delete
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeNullOrEmpty
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Value 'Ok, man'
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Comment
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeNullOrEmpty
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Uncomment
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeExactly 'Ok, man'
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Comment
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Delete
            Set-PhpIniKey -Path $phpIniPath -Key phpmanager_test -Uncomment
            Get-PhpIniKey -Path $phpIniPath -Key phpmanager_test | Should -BeNullOrEmpty
        } finally {
            try {
                if (Test-Path -LiteralPath $phpIniPath) {
                    Remove-Item -LiteralPath $phpIniPath -Force
                }
            } catch {
            }
        }
    }
    It 'must not allow setting "extension" keys in php.ini' {
        if (Test-Path -LiteralPath $phpIniPath) {
            Remove-Item -LiteralPath $phpIniPath -Force
        }
        try {
            { Set-PhpIniKey -Path $phpIniPath -Key extension -Value test } | Should -Throw
        } finally {
            try {
                if (Test-Path -LiteralPath $phpIniPath) {
                    Remove-Item -LiteralPath $phpIniPath -Force
                }
            } catch {
            }
        }
    }
    It 'must not allow setting "zend_extension" keys in php.ini' {
        if (Test-Path -LiteralPath $phpIniPath) {
            Remove-Item -LiteralPath $phpIniPath -Force
        }
        try {
            { Set-PhpIniKey -Path $phpIniPath -Key zend_extension -Value test } | Should -Throw
        } finally {
            try {
                if (Test-Path -LiteralPath $phpIniPath) {
                    Remove-Item -LiteralPath $phpIniPath -Force
                }
            } catch {
            }
        }
    }
}
