Describe 'Update-PhpCAInfo' {

    Mock -ModuleName PhpManager Get-PhpDownloadCache { return Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath download-cache }

    if (-Not(Test-Path -LiteralPath $Global:PHPMANAGER_TESTINSTALLS)) {
        New-Item -ItemType Directory -Path $Global:PHPMANAGER_TESTINSTALLS
    }
    $phpPath = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath (New-Guid).Guid
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

    $sourceTestCases = @(
        @{source = 'Curl'},
        @{source = 'LocalMachine'},
        @{source = 'CurrentUser'}
    )

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
            $webServerStdOut = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath 'https-server.log'
            $webServerStdErr = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath 'https-server.error.log'
            if (Test-Path -LiteralPath $webServerStdOut) {
                Remove-Item -LiteralPath $webServerStdOut -Recurse -Force
            }
            if (Test-Path -LiteralPath $webServerStdErr) {
                Remove-Item -LiteralPath $webServerStdErr -Recurse -Force
            }
            $localServerPort = 8043
            $localServerScript = Join-Path -Path $Global:PHPMANAGER_TESTINSTALLS -ChildPath 'https-server.js'
            Copy-Item -LiteralPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath 'https-server.js') -Destination $localServerScript -Force
            Copy-Item -LiteralPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath 'certs') -Destination $Global:PHPMANAGER_TESTINSTALLS -Recurse -Force
            $localServerArgs = @($localServerScript, $localServerPort)
            if ($PSVersionTable.PSEdition -eq 'Core') {
                $localServerProcess = Start-Process -FilePath 'node' -ArgumentList $localServerArgs -PassThru -RedirectStandardError $webServerStdErr -RedirectStandardOutput $webServerStdOut
            } else {
                $localServerProcess = Start-Process -FilePath 'node' -ArgumentList $localServerArgs -PassThru -RedirectStandardError $webServerStdErr -RedirectStandardOutput $webServerStdOut -WindowStyle Hidden
            }
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
                    $webServerStdOutContent = Get-Content -LiteralPath $webServerStdOut
                    if ($webServerStdOutContent -and $webServerStdOutContent -contains 'ready') {
                        break
                    }
                }
                Start-Sleep -Seconds 1
            }
        }
        It 'php should fail connecting to a server certificated with official CA when no CA certificate is configured' {
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            CheckHttps 'www.google.com' 443 | Should -Match '(curl:<.*>)|(openssl:<.*>)'
        }
        It 'php should fail connecting to a server certificated with custom CA when no CA certificate is configured' {
            if ($null -eq $localServerProcess) {
                Set-ItResult -Skipped -Because 'The test web server is not started (NodeJS is missing?)'
            }
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            CheckHttps 'localhost' $localServerPort | Should -Match '(curl:<.*>)|(openssl:<.*>)'
        }
        It 'php should succeed connecting to a server certificated with official CA when only official CA certificates are configured (<source> certs)' -TestCases $sourceTestCases {
            param ($source)
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath -Source $source
            CheckHttps 'www.google.com'  443 | Should -BeExactly 'curl:ok;openssl:ok'
        }
        It 'php should fail connecting to a server certificated with custom CA when only official CA certificates are configured' {
            if ($null -eq $localServerProcess) {
                Set-ItResult -Skipped -Because 'The test web server is not started (NodeJS is missing?)'
            }
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath
            CheckHttps 'localhost' $localServerPort | Should -Match '(curl:<.*>)|(openssl:<.*>)'
        }
        It 'php should succeed connecting to a server certificated with official CA when official CA certificates + custom CA certificate are configured' {
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath -CustomCAPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath certs | Join-Path -ChildPath 'ca.crt')
            CheckHttps 'www.google.com'  443 | Should -BeExactly 'curl:ok;openssl:ok'
        }
        It 'php should succeed connecting to a server certificated with custom CA when official CA certificates + custom CA certificate are configured' {
            if ($null -eq $localServerProcess) {
                Set-ItResult -Skipped -Because 'The test web server is not started (NodeJS is missing?)'
            }
            Set-PhpIniKey -Path $phpPath -Key 'curl.cainfo' -Delete
            Set-PhpIniKey -Path $phpPath -Key 'openssl.cafile' -Delete
            Update-PhpCAInfo -Path $phpPath -CustomCAPath (Join-Path -Path $Global:PHPMANAGER_TESTPATH -ChildPath certs | Join-Path -ChildPath 'ca.crt')
            CheckHttps 'localhost' $localServerPort | Should -BeExactly 'curl:ok;openssl:ok'
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
