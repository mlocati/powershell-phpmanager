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
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name (or the handle) of the PHP extension to be enabled')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string[]] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } Else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $extensionsToEnable = @()
        $allExtensions = Get-PhpExtension -Path $phpVersion.ExecutablePath
        ForEach ($wantedExtension in $Extension) {
            $foundExtensions = @($allExtensions | Where-Object {$_.Name -like $wantedExtension})
            If ($foundExtensions.Count -ne 1) {
                $foundExtensions = @($allExtensions | Where-Object {$_.Handle -like $wantedExtension})
                If ($foundExtensions.Count -eq 0) {
                    throw "Unable to find a locally available extension with name (or handle) `"$Extension`": use the Install-PhpExtension to download it"
                }
                If ($foundExtensions.Count -ne 1) {
                    throw "Multiple extensions match the name (or handle) `"$Extension`""
                }
            }
            $extensionsToEnable += $foundExtensions[0]
        }
        $iniPath = $phpVersion.IniPath
        $extensionDir = $null
        $iniLines = @(Get-PhpIniLine -Path $iniPath)
        ForEach ($extensionToEnable in $extensionsToEnable) {
            $extensionDir = $phpVersion.ExtensionsPath
            If (-Not($extensionDir)) {
                $extensionDir = Split-Path -LiteralPath $extensionToEnable.Filename
                Set-PhpIniKey -Key 'extension_dir' -Value $extensionDir -Path $iniPath
            }
            $extensionDir = $extensionDir.TrimEnd('/', '\') + [System.IO.Path]::DirectorySeparatorChar
            If ($extensionToEnable.State -eq $Script:EXTENSIONSTATE_BUILTIN) {
                Write-Output ('The extension "' + $extensionToEnable.Name + '" is builtin: it''s enabled by default')
            } ElseIf ($extensionToEnable.State -eq $Script:EXTENSIONSTATE_ENABLED) {
                Write-Output ('The extension "' + $extensionToEnable.Name + '" is already enabled')
            } ElseIf ($extensionToEnable.State -ne $Script:EXTENSIONSTATE_DISABLED) {
                Throw ('Unknown extension state: "' + $extensionToEnable.State + '"')
            } Else {
                Switch ($extensionToEnable.Type) {
                    $Script:EXTENSIONTYPE_PHP { $iniKey = 'extension' }
                    $Script:EXTENSIONTYPE_ZEND { $iniKey = 'zend_extension' }
                    default { Throw ('Unrecognized extension type: ' + $extensionToEnable.Type) }
                }
                $filename = [System.IO.Path]::GetFileName($extensionToEnable.Filename)
                $canUseBaseName = [System.Version]$phpVersion.Version -ge [System.Version]'7.2'
                $rxSearch = '^(\s*)([;#][\s;#]*)?(\s*(?:zend_)?extension\s*=\s*)('
                $rxSearch += '(?:(?:.*[/\\])?' + [regex]::Escape($filename) + ')';
                If ($canUseBaseName) {
                    $match = $filename | Select-String -Pattern '^php_(.+)\.dll$'
                    if ($match) {
                        $rxSearch += '|(?:' + [regex]::Escape($match.Matches[0].Groups[1].Value) + ')'
                    }
                }
                $rxSearch += ')"?\s*$'
                If ($extensionToEnable.Filename -like ($extensionDir + '*')) {
                    $newIniValue = $extensionToEnable.Filename.SubString($extensionDir.Length)
                    If ($canUseBaseName) {
                        $match = $newIniValue | Select-String -Pattern '^php_(.+)\.dll$'
                        If ($match) {
                            $newIniValue = $match.Matches[0].Groups[1].Value
                        }
                    } ElseIf ([System.Version]$phpVersion.Version -le [System.Version]'5.4.99999') {
                        $newIniValue = $extensionToEnable.Filename
                    }
                } Else {
                    $newIniValue = $extensionToEnable.Filename
                }
                $found = $false
                $newIniLines = @()
                ForEach ($line in $iniLines) {
                    $match = $line | Select-String -Pattern $rxSearch
                    if ($null -eq $match) {
                        $newIniLines += $line
                    } ElseIf (-Not($found)) {
                        $found = $true
                        $newIniLines += $match.Matches[0].Groups[1].Value + "$iniKey=$newIniValue"
                    }
                }
                If (-Not($found)) {
                    $newIniLines += "$iniKey=$newIniValue"
                }
                Set-PhpIniLine -Path $iniPath -Lines $newIniLines
                $extensionToEnable.State = $Script:EXTENSIONSTATE_ENABLED
                Write-Output ('The extension ' + $extensionToEnable.Name + ' v' + $extensionToEnable.Version + ' has been enabled')
                $iniLines = $newIniLines
            }
        }
    }
    End {
    }
}
