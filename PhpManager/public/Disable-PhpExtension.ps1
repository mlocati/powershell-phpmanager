function Disable-PhpExtension() {
    <#
    .Synopsis
    Disables a PHP extension.

    .Description
    Disables a PHP extension (if it's enable and if it's not a builtin extension).

    .Parameter Extension
    The name (or the handle) of the PHP extension to be disabled.
    You can specify more that one value.

    .Parameter Path
    The path to the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Parameter Comment
    Specify this switch to comment the line in the php.ini file instead of removing it

    .Example
    Disable-PhpExtension gd

    .Example
    Disable-PhpExtension gd,mbstring

    .Example
    Disable-PhpExtension gd C:\Path\To\Php

    .Example
    Disable-PhpExtension gd C:\Path\To\Php -Comment
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name (or the handle) of the PHP extension to be disabled')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string[]] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Path,
        [switch] $Comment
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $allExtensions = Get-PhpExtension -Path $phpVersion.ExecutablePath
        $extensionsToDisable = @()
        foreach ($wantedExtension in $Extension) {
            $foundExtensions = @($allExtensions | Where-Object { $_.Name -like $wantedExtension })
            if ($foundExtensions.Count -eq 0) {
                $foundExtensions = @($allExtensions | Where-Object { $_.Handle -like $wantedExtension })
                if ($foundExtensions.Count -eq 0) {
                    throw "Unable to find a locally available extension with name (or handle) `"$wantedExtension`": use the Enab-PhpExtension to download it"
                }
            }
            foreach ($extensionToDisable in $foundExtensions) {
                if ($extensionToDisable.State -eq $Script:EXTENSIONSTATE_BUILTIN) {
                    throw ('The extension "' + $extensionToDisable.Name + '" is builtin: it can''t be disabled')
                }
                if ($extensionToDisable.State -eq $Script:EXTENSIONSTATE_DISABLED) {
                    Write-Verbose ('The extension "' + $extensionToDisable.Name + '" is already disabled')
                } elseif ($extensionToDisable.State -ne $Script:EXTENSIONSTATE_ENABLED) {
                    throw ('Unknown extension state: "' + $extensionToDisable.State + '"')
                } else {
                    $extensionsToDisable += $extensionToDisable
                }
            }
        }
        if ($extensionsToDisable) {
            $iniPath = $phpVersion.IniPath
            if (-Not(Test-Path -Path $iniPath -PathType Leaf)) {
                throw "There file $iniPath does not exist (?)"
            }
            $iniLines = @(Get-PhpIniLine -Path $iniPath)
            foreach ($extensionToDisable in $extensionsToDisable) {
                $filename = [System.IO.Path]::GetFileName($extensionToDisable.Filename)
                $canUseBaseName = [System.Version]$phpVersion.Version -ge [System.Version]'7.2'
                $rxSearch = '^(\s*)([;#][\s;#]*)?(\s*(?:zend_)?extension\s*=\s*(?:'
                $rxSearch += '(?:(?:.*[/\\])?' + [regex]::Escape($filename) + ')';
                if ($canUseBaseName) {
                    $match = $filename | Select-String -Pattern '^php_(.+)\.dll$'
                    if ($match) {
                        $rxSearch += '|(?:' + [regex]::Escape($match.Matches[0].Groups[1].Value) + ')'
                    }
                }
                $rxSearch += '))"?\s*$'
                $disabled = $false
                $newIniLines = @()
                foreach ($line in $iniLines) {
                    $match = $line | Select-String -Pattern $rxSearch
                    if ($null -eq $match) {
                        $newIniLines += $line
                    } else {
                        if ($match.Matches[0].Groups[2].Value -eq '') {
                            $disabled = $true
                            if ($Comment) {
                                $newIniLines += $match.Matches[0].Groups[1].Value + ';' + $match.Matches[0].Groups[3].Value
                            }
                        } elseif ($Comment) {
                            $newIniLines += $line
                        }
                    }
                }
                if ($disabled) {
                    Set-PhpIniLine -Path $iniPath -Lines $newIniLines
                    $extensionToDisable.State = $Script:EXTENSIONSTATE_ENABLED
                    Write-Verbose ('The extension ' + $extensionToDisable.Name + ' v' + $extensionToDisable.Version + ' has been disabled')
                    $iniLines = $newIniLines
                }
            }
        }
    }
    end {
    }
}
