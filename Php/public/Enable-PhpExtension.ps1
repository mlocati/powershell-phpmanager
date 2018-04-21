function Enable-PhpExtension() {
    <#
    .Synopsis
    Enables a PHP extension.

    .Description
    Enables a PHP extension (if it's not already enabled and if it's not a builtin extension).

    .Parameter Extension
    The name (or the handle) of the PHP extension to be enabled.

    .Parameter Path
    The path to the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.
    #>
    Param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name (or the handle) of the PHP extension to be enabled')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path
    )
    Begin {
    }
    Process {
        If ($Path -eq $null -or $Path -eq '') {
            $phpVersion = Get-OnePhpVersionFromEnvironment
        } Else {
            $phpVersion = Get-PhpVersionFromPath -Path $Path
        }
        $allExtensions = Get-PhpExtensions -Path $phpVersion.ExecutablePath
        $foundExtensions = @($allExtensions | Where-Object {$_.Name -like $Extension})
        If ($foundExtensions.Count -ne 1) {
            $foundExtensions = @($allExtensions | Where-Object {$_.Handle -like $Extension})
            If ($foundExtensions.Count -eq 0) {
                throw "Unable to find a locally available extension with name (or handle) `"$Extension`": use the Install-PhpExtension to download it"
            }
            If ($foundExtensions.Count -ne 1) {
                throw "Multiple extensions match the name (or handle) `"$Extension`""
            }
        }
        $extensionToEnable = $foundExtensions[0]
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
            $iniPath = $phpVersion.IniPath
            If (-Not($iniPath)) {
                $iniPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($phpVersion.ExecutablePath), 'php.ini')
            }
            $extensionDir = $phpVersion.ExtensionsPath
            If (-Not($extensionDir)) {
                $extensionDir = [System.IO.Path]::GetDirectoryName($extensionToEnable.Filename)
                Set-PhpIniKey -Key 'extension_dir' -Value $extensionDir -Path $iniPath
            }
            $extensionDir = $extensionDir.TrimEnd('/', '\') + [System.IO.Path]::DirectorySeparatorChar
            $filename = [System.IO.Path]::GetFileName($extensionToEnable.Filename)
            $canUseBaseName = [System.Version]$phpVersion.BaseVersion -ge [System.Version]'7.2'
            $rxSearch = '^(\s*)([;#][\s;#]*)?(\s*(?:zend_)?extension\s*=\s*)('
            $rxSearch += '(?:(?:.*[/\\])?' + [regex]::Escape($filename) + ')';
            If ($canUseBaseName) {
                $match = $filename | Select-String -Pattern  '^php_(.+)\.dll$'
                if ($match) {
                    $rxSearch += '|(?:' + [regex]::Escape($match.Matches[0].Groups[1].Value) + ')'
                }
            }
            $rxSearch += ')\s*$'
            If ($extensionToEnable.Filename -like ($extensionDir + '*')) {
                $newIniValue = $extensionToEnable.Filename.SubString($extensionDir.Length)
                If ($canUseBaseName) {
                    $match = $newIniValue | Select-String -Pattern  '^php_(.+)\.dll$'
                    If ($match) {
                        $newIniValue = $match.Matches[0].Groups[1].Value
                    }
                }
            } Else {
                $newIniValue = $extensionToEnable.Filename
            }
            $found = $false
            $newIniLines = @()
            $iniLines = Get-PhpIniLines -Path $iniPath
            ForEach ($line in $iniLines) {
                $match = $line | Select-String -Pattern $rxSearch
                if ($match -eq $null) {
                    $newIniLines += $line
                } ElseIf (-Not($found)) {
                    $found = $true
                    $newIniLines += $match.Matches[0].Groups[1].Value + "$iniKey=$newIniValue"
                }
            }
            If (-Not($found)) {
                $newIniLines += "$iniKey=$newIniValue"
            }
            Set-PhpIniLines -Path $iniPath -Lines $newIniLines
            $extensionToEnable.State = $Script:EXTENSIONSTATE_ENABLED
            Write-Output ('The extension ' + $extensionToEnable.Name + ' v' + $extensionToEnable.Version + ' has been enabled')
        }
    }
    End {
    }
}
