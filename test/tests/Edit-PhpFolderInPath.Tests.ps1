Describe 'Edit-PhpFolderInPath' {
    $pathSeparator = [System.IO.Path]::PathSeparator
    function GetFakeDir() {
        return 'C:\This\Directory\Should\Not\Exist\' + (New-Guid).Guid
    }
    function GetPath([string][ValidateSet('Env', 'User', 'System')]$what) {
        if ($what -eq 'Env') {
            $result = $Env:Path
        } else {
            if ($what -eq 'User') {
                $key = 'HKCU:\Environment'
            } else {
                $key = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
            }
            $result = ''
            if (Test-Path -LiteralPath $key) {
                $pathProperties = Get-ItemProperty -LiteralPath $key -Name 'Path'
                if ($pathProperties | Get-Member -Name 'Path') {
                    $result = $pathProperties.Path
                    if ($null -eq $result) {
                        $result = $result
                    }
                }
            }
        }
        if ($null -eq $result) {
            $result = ''
        } else {
            $result = $result -replace ('^' + [regex]::Escape($pathSeparator) + '+'), ''
            $result = $result -replace ([regex]::Escape($pathSeparator) + '+$'), ''
            $result = $result -replace ([regex]::Escape($pathSeparator) + '{2,}'), $pathSeparator
        }
        return $result
    }

    $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdministrator = $currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    $runAs = $null -ne $Env:PHPMANAGER_TEST_RUNAS -and '' -ne $Env:PHPMANAGER_TEST_RUNAS -and '0' -ne $Env:PHPMANAGER_TEST_RUNAS -and 'false' -ne $Env:PHPMANAGER_TEST_RUNAS

    It 'shouldn''t do anything' {
        $dir = GetFakeDir
        $preEnv = GetPath('Env')
        $preUser = GetPath('User')
        $preSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Add -Path $dir
        $postEnv = GetPath('Env')
        $postUser = GetPath('User')
        $postSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Remove -Path $dir
        $postEnv | Should -BeExactly $preEnv
        $postUser | Should -BeExactly $preUser
        $postSystem | Should -BeExactly $preSystem
        GetPath('Env') | Should -BeExactly $preEnv
        GetPath('User') | Should -BeExactly $preUser
        GetPath('System') | Should -BeExactly $preSystem
    }

    It 'should set ENV' {
        $dir = GetFakeDir
        $preEnv = GetPath('Env')
        $preUser = GetPath('User')
        $preSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Add -Path $dir -CurrentProcess
        $postEnv = GetPath('Env')
        $postUser = GetPath('User')
        $postSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Remove -Path $dir
        $postEnv | Should -BeExactly "$preEnv$pathSeparator$dir".TrimStart($pathSeparator)
        $postUser | Should -BeExactly $preUser
        $postSystem | Should -BeExactly $preSystem
        GetPath('Env') | Should -BeExactly $preEnv
        GetPath('User') | Should -BeExactly $preUser
        GetPath('System') | Should -BeExactly $preSystem
    }

    It 'should set USER' {
        $dir = GetFakeDir
        $preEnv = GetPath('Env')
        $preUser = GetPath('User')
        $preSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Add -Path $dir -Persist User
        $postEnv = GetPath('Env')
        $postUser = GetPath('User')
        $postSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Remove -Path $dir
        $postEnv | Should -BeExactly $preEnv
        $postUser | Should -BeExactly "$preUser$pathSeparator$dir".TrimStart($pathSeparator)
        $postSystem | Should -BeExactly $preSystem
        GetPath('Env') | Should -BeExactly $preEnv
        GetPath('User') | Should -BeExactly $preUser
        GetPath('System') | Should -BeExactly $preSystem
    }

    if ($isAdministrator -or $runAs) {
        It 'should set SYSTEM' {
            $dir = GetFakeDir
            $preEnv = GetPath('Env')
            $preUser = GetPath('User')
            $preSystem = GetPath('System')
            Edit-PhpFolderInPath -Operation Add -Path $dir -Persist System
            $postEnv = GetPath('Env')
            $postUser = GetPath('User')
            $postSystem = GetPath('System')
            Edit-PhpFolderInPath -Operation Remove -Path $dir
            $postEnv | Should -BeExactly $preEnv
            $postUser | Should -BeExactly $preUser
            $postSystem | Should -BeExactly "$preSystem$pathSeparator$dir".TrimStart($pathSeparator)
            GetPath('Env') | Should -BeExactly $preEnv
            GetPath('User') | Should -BeExactly $preUser
            GetPath('System') | Should -BeExactly $preSystem
        }
    } else {
        It 'should set SYSTEM' -Skip {
        }
    }

    It 'should set ENV and USER' {
        $dir = GetFakeDir
        $preEnv = GetPath('Env')
        $preUser = GetPath('User')
        $preSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Add -Path $dir -Persist User -CurrentProcess
        $postEnv = GetPath('Env')
        $postUser = GetPath('User')
        $postSystem = GetPath('System')
        Edit-PhpFolderInPath -Operation Remove -Path $dir
        $postEnv | Should -BeExactly "$preEnv$pathSeparator$dir".TrimStart($pathSeparator)
        $postUser | Should -BeExactly "$preUser$pathSeparator$dir".TrimStart($pathSeparator)
        $postSystem | Should -BeExactly $preSystem
        GetPath('Env') | Should -BeExactly $preEnv
        GetPath('User') | Should -BeExactly $preUser
        GetPath('System') | Should -BeExactly $preSystem
    }

    if ($isAdministrator -or $runAs) {
        It 'should set ENV and SYSTEM' {
            $dir = GetFakeDir
            $preEnv = GetPath('Env')
            $preUser = GetPath('User')
            $preSystem = GetPath('System')
            Edit-PhpFolderInPath -Operation Add -Path $dir -Persist System -CurrentProcess
            $postEnv = GetPath('Env')
            $postUser = GetPath('User')
            $postSystem = GetPath('System')
            Edit-PhpFolderInPath -Operation Remove -Path $dir
            $postEnv | Should -BeExactly "$preEnv$pathSeparator$dir".TrimStart($pathSeparator)
            $postUser | Should -BeExactly $preUser
            $postSystem | Should -BeExactly "$preSystem$pathSeparator$dir".TrimStart($pathSeparator)
            GetPath('Env') | Should -BeExactly $preEnv
            GetPath('User') | Should -BeExactly $preUser
            GetPath('System') | Should -BeExactly $preSystem
        }
    } else {
        It 'should set ENV and SYSTEM' -Skip {
        }
    }
}
