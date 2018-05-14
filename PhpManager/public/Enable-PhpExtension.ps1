function Enable-PhpExtension() {
    <#
    .Synopsis
    Enables a PHP extension.

    .Description
    Enables a PHP extension (if it's not already enabled and if it's not a builtin extension).

    .Parameter Extension
    The name (or the handle) of the PHP extension to be enabled.
    You can specify more that one value.

    .Parameter Path
    The path to the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Example
    Enable-PhpExtension gd

    .Example
    Enable-PhpExtension gd,mbstring

    .Example
    Enable-PhpExtension gd C:\Path\To\Php
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name (or the handle) of the PHP extension to be enabled')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string[]] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $extensionsToEnable = @()
        $allExtensions = Get-PhpExtension -Path $phpVersion.ExecutablePath
        foreach ($wantedExtension in $Extension) {
            $match = $wantedExtension | Select-String -Pattern '^([^:]*)(?::(.*))?$'
            $wantedExtensionName = $match.Matches.Groups[1].Value
            $wantedExtensionVersion = $match.Matches.Groups[2].Value
            $foundExtensions = @($allExtensions | Where-Object { $_.Name -like $wantedExtensionName -and $_.Version -like ($wantedExtensionVersion + '*') })
            if ($foundExtensions.Count -ne 1) {
                $foundExtensions = @($allExtensions | Where-Object { $_.Handle -like $wantedExtensionName -and $_.Version -like ($wantedExtensionVersion + '*') })
                if ($foundExtensions.Count -eq 0) {
                    throw "Unable to find a locally available extension with name (or handle) `"$Extension`": use the Install-PhpExtension to download it"
                }
                if ($foundExtensions.Count -ne 1) {
                    $msg = "Multiple extensions match the name (or handle) `"$Extension`":"
                    foreach ($foundExtension in $foundExtensions) {
                        $msg += "`n- handle: $($foundExtension.Handle) version $($foundExtension.Version)"
                    }
                    $msg += "`nYou can filter the extension to enable by adding :version to the -Extension parameter (example: `"-Extension '$($foundExtension.Handle):$($foundExtension.Version)'`")"
                    throw $msg
                }
            }
            $extensionsToEnable += $foundExtensions[0]
        }
        $iniPath = $phpVersion.IniPath
        $extensionDir = $null
        $iniLines = @(Get-PhpIniLine -Path $iniPath)
        foreach ($extensionToEnable in $extensionsToEnable) {
            $extensionDir = $phpVersion.ExtensionsPath
            if (-Not($extensionDir)) {
                $extensionDir = Split-Path -LiteralPath $extensionToEnable.Filename
                Set-PhpIniKey -Key 'extension_dir' -Value $extensionDir -Path $iniPath
            }
            $extensionDir = $extensionDir.TrimEnd('/', '\') + [System.IO.Path]::DirectorySeparatorChar
            if ($extensionToEnable.State -eq $Script:EXTENSIONSTATE_BUILTIN) {
                Write-Verbose ('The extension "' + $extensionToEnable.Name + '" is builtin: it''s enabled by default')
            } elseif ($extensionToEnable.State -eq $Script:EXTENSIONSTATE_ENABLED) {
                Write-Verbose ('The extension "' + $extensionToEnable.Name + '" is already enabled')
            } elseif ($extensionToEnable.State -ne $Script:EXTENSIONSTATE_DISABLED) {
                throw ('Unknown extension state: "' + $extensionToEnable.State + '"')
            } else {
                switch ($extensionToEnable.Type) {
                    $Script:EXTENSIONTYPE_PHP { $iniKey = 'extension' }
                    $Script:EXTENSIONTYPE_ZEND { $iniKey = 'zend_extension' }
                    default { throw ('Unrecognized extension type: ' + $extensionToEnable.Type) }
                }
                $filename = [System.IO.Path]::GetFileName($extensionToEnable.Filename)
                $canUseBaseName = [System.Version]$phpVersion.Version -ge [System.Version]'7.2'
                $rxSearch = '^(\s*)([;#][\s;#]*)?(\s*(?:zend_)?extension\s*=\s*)('
                $rxSearch += '(?:(?:.*[/\\])?' + [regex]::Escape($filename) + ')';
                if ($canUseBaseName) {
                    $match = $filename | Select-String -Pattern '^php_(.+)\.dll$'
                    if ($match) {
                        $rxSearch += '|(?:' + [regex]::Escape($match.Matches[0].Groups[1].Value) + ')'
                    }
                }
                $rxSearch += ')"?\s*$'
                if ($extensionToEnable.Filename -like ($extensionDir + '*')) {
                    $newIniValue = $extensionToEnable.Filename.SubString($extensionDir.Length)
                    if ($canUseBaseName) {
                        $match = $newIniValue | Select-String -Pattern '^php_(.+)\.dll$'
                        if ($match) {
                            $newIniValue = $match.Matches[0].Groups[1].Value
                        }
                    } elseif ([System.Version]$phpVersion.Version -le [System.Version]'5.4.99999') {
                        $newIniValue = $extensionToEnable.Filename
                    }
                } else {
                    $newIniValue = $extensionToEnable.Filename
                }
                $found = $false
                $newIniLines = @()
                foreach ($line in $iniLines) {
                    $match = $line | Select-String -Pattern $rxSearch
                    if ($null -eq $match) {
                        $newIniLines += $line
                    } elseif (-Not($found)) {
                        $found = $true
                        $newIniLines += $match.Matches[0].Groups[1].Value + "$iniKey=$newIniValue"
                    }
                }
                if (-Not($found)) {
                    $newIniLines += "$iniKey=$newIniValue"
                }
                Set-PhpIniLine -Path $iniPath -Lines $newIniLines
                $extensionToEnable.State = $Script:EXTENSIONSTATE_ENABLED
                Write-Verbose ('The extension ' + $extensionToEnable.Name + ' v' + $extensionToEnable.Version + ' has been enabled')
                $iniLines = $newIniLines
            }
        }
    }
    end {
    }
}
