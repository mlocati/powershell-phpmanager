﻿function Install-Composer() {
    <#
    .Synopsis
    Installs Composer.

    .Description
    Download and install Composer, the PHP dependency manager.

    .Parameter Path
    Specify where Composer will be installed.
    If not specified, we'll install it in C:\ProgramData\ComposerBin for system-wide installations, or in C:\Users\<user>\AppData\Local\ComposerBin for user-specific installations.

    .Parameter PhpPath
    The path of PHP (if not specified, we'll detect it).

    .Parameter Scope
    Install Composer the current user only ('User' - default), or at system-level ('System').

    .Parameter NoAddToPath
    Specify this option to don't add the Composer install path to the PATH environment variable.

    .Parameter NoCache
    Specify this option to don't use a previously downloaded Composer installer.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'Composer install location')]
        [string] $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Where PHP is installed')]
        [string] $PhpPath,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'Install for current user of for any user')]
        [ValidateSet('User', 'System')]
        [string] $Scope,
        [switch] $NoAddToPath,
        [switch] $NoCache
    )
    begin {
    }
    process {
        if ($null -eq $Path -or '' -eq $Path) {
            if ($Scope -eq 'System') {
                $Path = [Environment]::GetFolderPath('CommonApplicationData')
            } else {
                $Path = [Environment]::GetFolderPath('LocalApplicationData')
            }
            $Path = Join-Path -Path $Path -ChildPath 'ComposerBin'
        }
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            throw "The specified installation path ($Path) points to an existing file"
        }
        if ($null -eq $PhpPath -or $PhpPath -eq '') {
            $phpAutodetect = $true
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
            Write-Verbose ('PHP detected at ' + $phpVersion.Folder)
        } else {
            $phpAutodetect = $false
            $phpVersion = [PhpVersionInstalled]::FromPath($PhpPath)
        }
        $installerUrl = 'https://getcomposer.org/installer';
        $installer = ''
        $tempPhar = ''
        $pathCreatedHere = $false
        try {
            if ($NoCache) {
                $installer = [System.IO.Path]::GetTempFileName();
                Set-NetSecurityProtocolType
                Write-Verbose "Downloading from $installerUrl"
                Invoke-WebRequest -UseBasicParsing $installerUrl -OutFile $installer
            } else {
                $installer = Get-FileFromUrlOrCache -Url $installerUrl -CachedFileName 'composer-installer.php'
            }
            $tempPhar  = [System.IO.Path]::GetTempFileName();
            $args = @()
            $args += $installer
            $args += '--install-dir=' + (Split-Path -Path $tempPhar -Parent)
            $args += '--filename=' + (Split-Path -Path $tempPhar -Leaf)
            $args += '2>&1'
            Write-Verbose "Launching Composer installer"
            $installerResult = & $phpVersion.ExecutablePath $args
            if ($LASTEXITCODE -ne 0) {
                throw $installerResult
            }
            Write-Verbose "Composer succeeded"
            Write-Verbose "Installing to $Path"
            If (-Not(Test-Path -LiteralPath $Path)) {
                New-Item -ItemType Directory -Path $Path | Out-Null
                $pathCreatedHere = $true
            }
            Write-Verbose "Moving composer.phar"
            $destPhar = Join-Path -Path $Path -ChildPath 'composer.phar'
            if (Test-Path -LiteralPath $destPhar -PathType Leaf) {
                Remove-Item -LiteralPath $destPhar
            }
            Move-Item -LiteralPath $tempPhar -Destination $destPhar -Force
            Write-Verbose "Creating composer.bat"
            $lines = @()
            $lines += '@echo off'
            $lines += 'setlocal disabledelayedexpansion'
            $lines += ''
            if ($phpAutodetect) {
                $line = 'php.exe';
            } else {
                $line = '"' + $phpVersion.ExecutablePath + '"';
            }
            $lines += $line + ' "%~dpn0.phar" %*'
            $destBat = Join-Path -Path $Path -ChildPath 'composer.bat'
            Set-Content -Path $destBat -Value $lines
            if (-not($NoAddToPath)) {
                Write-Verbose 'Adding to PATH'
                Edit-FolderInPath -Operation Add -Path $Path -Persist $Scope -CurrentProcess
            }
        } catch {
            if ($pathCreatedHere) {
                try {
                    Remove-Item -LiteralPath $Path -Recurse
                } catch {
                    Write-Debug 'Failed to remove extraction directory'
                }
            }
            throw
        } finally {
            if ($NoCache -and $installer -ne '') {
                if (Test-Path -LiteralPath $installer -PathType Leaf) {
                    Remove-Item -LiteralPath $installer
                }
            }
            if ($tempPhar -ne '') {
                if (Test-Path -LiteralPath $tempPhar -PathType Leaf) {
                    Remove-Item -LiteralPath $tempPhar
                }
            }
        }
    }
    end {
    }
}
