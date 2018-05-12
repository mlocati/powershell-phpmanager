Describe 'Update-PhpCAInfo' {

    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }

    $installsPath = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs
    if (-Not(Test-Path -LiteralPath $installsPath)) {
        New-Item -ItemType Directory -Path $installsPath
    }
    $phpPath = Join-Path -Path $installsPath -ChildPath (New-Guid).Guid
    if (Test-Path -LiteralPath $phpPath) {
        Remove-Item -LiteralPath $phpPath -Recurse -Force
    }
    function CheckHttps($hostToCheck, $portToCheck) {
        $phpScript = Split-Path -LiteralPath $PSScriptRoot | Join-Path -ChildPath 'test-https.php'
        $phpExe = Join-Path -Path $phpPath -ChildPath 'php.exe'
        $phpOutput = & $phpExe @($phpScript, $hostToCheck, $portToCheck)
        if ($LASTEXITCODE -ne 0) {
            throw "PHP script failed with exit code $LASTEXITCODE"
        }
        $phpOutput
    }
    $localServerProcess = $null
    $phpInstalled = $false
    try {
        $startWebServer = $false
        try {
            & 'node' '--version' 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $startWebServer = $true
            }
        } catch {
        }
        if ($startWebServer) {
            $webServerStdOut = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath 'https-server.log'
            $webServerStdErr = Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath installs | Join-Path -ChildPath 'https-server.error.log'
            if (Test-Path -LiteralPath $webServerStdOut) {
                Remove-Item -LiteralPath $webServerStdOut -Recurse -Force
            }
            if (Test-Path -LiteralPath $webServerStdErr) {
                Remove-Item -LiteralPath $webServerStdErr -Recurse -Force
            }
            $localServerPort = 8043
            $localServerArgs = @()
            $localServerArgs += Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath 'https-server.js'
            $localServerArgs += $localServerPort
            $localServerProcess = Start-Process -FilePath 'node' -ArgumentList $localServerArgs -PassThru -RedirectStandardError $webServerStdErr -RedirectStandardOutput $webServerStdOut -WindowStyle Hidden
            if ($null -eq $localServerProcess) {
                throw 'Unable to start a local web server'
            }
        }
        Install-Php -Version 7.1 -Architecture x64 -ThreadSafe $true -Path $phpPath
        $phpInstalled = $true
        Enable-PhpExtension -Extension curl,openssl -Path $phpPath
        if ($null -ne $localServerProcess) {
            for (;;) {
                if ($localServerProcess.HasExited) {
                    throw 'Premature end of local web server'
                }
                if (Test-Path -LiteralPath $webServerStdOut) {
                    $webServerStdOut = Get-Content -LiteralPath $webServerStdOut
                    if ($webServerStdOut -and $webServerStdOut -contains 'ready') {
                        break
                    }
                }
                Start-Sleep -Seconds 1
            }
        }
        It 'php should fail connecting to a server certificated with official CA when no CA certificate is configured' {
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            CheckHttps 'www.google.com' 443 | Should -BeLike 'curl:<*>;openssl:<*>'
        }
        if ($null -ne $localServerProcess) {
            It 'php should fail connecting to a server certificated with custom CA when no CA certificate is configured' {
                Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
                Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
                CheckHttps 'localhost' $localServerPort | Should -BeLike 'curl:<*>;openssl:<*>'
            }
        } else {
            It 'php should fail connecting to a server certificated with custom CA when no CA certificate is configured' -Skip {
            }
        }
        It 'php should succeed connecting to a server certificated with official CA when only official CA certificates are configured' {
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath
            CheckHttps 'www.google.com'  443 | Should -BeExactly 'curl:ok;openssl:ok'
        }
        if ($null -ne $localServerProcess) {
            It 'php should fail connecting to a server certificated with custom CA when only official CA certificates are configured' {
                Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
                Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
                Update-PhpCAInfo -Path $phpPath
                CheckHttps 'localhost' $localServerPort | Should -BeLike 'curl:<*>;openssl:<*>'
            }
        } else {
            It 'php should fail connecting to a server certificated with custom CA when only official CA certificates are configured' -Skip {
            }
        }
        It 'php should succeed connecting to a server certificated with official CA when official CA certificates + custom CA certificate are configured' {
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath -CustomCAPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath certs | Join-Path -ChildPath 'ca.crt')
            CheckHttps 'www.google.com'  443 | Should -BeExactly 'curl:ok;openssl:ok'
        }
        if ($null -ne $localServerProcess) {
            It 'php should succeed connecting to a server certificated with custom CA when official CA certificates + custom CA certificate are configured' {
                Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
                Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
                Update-PhpCAInfo -Path $phpPath -CustomCAPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath certs | Join-Path -ChildPath 'ca.crt')
                CheckHttps 'localhost' $localServerPort | Should -BeExactly 'curl:ok;openssl:ok'
            }
        } else {
            It 'php should succeed connecting to a server certificated with custom CA when official CA certificates + custom CA certificate are configured' -Skip {
            }
        }
    } finally {
        if ($phpInstalled) {
            try {
                Remove-Item -LiteralPath $phpPath -Recurse -Force
            } catch {
            }
        }
        if ($null -ne $localServerProcess) {
            try {
                Stop-Process $localServerProcess
            } catch {
            }
        }
    }
}
