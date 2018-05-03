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
    Param(
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
    Begin {
    }
    Process {
        If ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } Else {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        $allExtensions = Get-PhpExtension -Path $phpVersion.ExecutablePath
        $extensionsToDisable = @()
        ForEach ($wantedExtension in $Extension) {
            $foundExtensions = @($allExtensions | Where-Object {$_.Name -like $wantedExtension})
            If ($foundExtensions.Count -ne 1) {
                $foundExtensions = @($allExtensions | Where-Object {$_.Handle -like $wantedExtension})
                If ($foundExtensions.Count -eq 0) {
                    throw "Unable to find a locally available extension with name (or handle) `"$wantedExtension`": use the Enab-PhpExtension to download it"
                }
                If ($foundExtensions.Count -ne 1) {
                    throw "Multiple extensions match the name (or handle) `"$wantedExtension`""
                }
            }
            $extensionToDisable = $foundExtensions[0]
            If ($extensionToDisable.State -eq $Script:EXTENSIONSTATE_BUILTIN) {
                Throw ('The extension "' + $extensionToDisable.Name + '" is builtin: it can''t be disabled')
            }
            If ($extensionToDisable.State -eq $Script:EXTENSIONSTATE_DISABLED) {
                Write-Output ('The extension "' + $extensionToDisable.Name + '" is already disabled')
            } ElseIf ($extensionToDisable.State -ne $Script:EXTENSIONSTATE_ENABLED) {
                Throw ('Unknown extension state: "' + $extensionToDisable.State + '"')
            } Else {
                $extensionsToDisable += $extensionToDisable
            }
        }
        If ($extensionsToDisable) {
            $iniPath = $phpVersion.IniPath
            If (-Not(Test-Path -Path $iniPath -PathType Leaf)) {
                Throw "There file $iniPath does not exist (?)"
            }
            $iniLines = @(Get-PhpIniLine -Path $iniPath)
            ForEach ($extensionToDisable in $extensionsToDisable) {
                $filename = [System.IO.Path]::GetFileName($extensionToDisable.Filename)
                $canUseBaseName = [System.Version]$phpVersion.Version -ge [System.Version]'7.2'
                $rxSearch = '^(\s*)([;#][\s;#]*)?(\s*(?:zend_)?extension\s*=\s*(?:'
                $rxSearch += '(?:(?:.*[/\\])?' + [regex]::Escape($filename) + ')';
                If ($canUseBaseName) {
                    $match = $filename | Select-String -Pattern '^php_(.+)\.dll$'
                    if ($match) {
                        $rxSearch += '|(?:' + [regex]::Escape($match.Matches[0].Groups[1].Value) + ')'
                    }
                }
                $rxSearch += '))"?\s*$'
                $disabled = $false
                $newIniLines = @()
                ForEach ($line in $iniLines) {
                    $match = $line | Select-String -Pattern $rxSearch
                    if ($null -eq $match) {
                        $newIniLines += $line
                    } Else {
                        If ($match.Matches[0].Groups[2].Value -eq '') {
                            $disabled = $true
                            If ($Comment) {
                                $newIniLines += $match.Matches[0].Groups[1].Value + ';' + $match.Matches[0].Groups[3].Value
                            }
                        } ElseIf ($Comment) {
                            $newIniLines += $line
                        }
                    }
                }
                If (-Not($disabled)) {
                    Throw "The entry in the php.ini file has not been found (?)"
                }
                Set-PhpIniLine -Path $iniPath -Lines $newIniLines
                $extensionToDisable.State = $Script:EXTENSIONSTATE_ENABLED
                Write-Output ('The extension ' + $extensionToDisable.Name + ' v' + $extensionToDisable.Version + ' has been disabled')
                $iniLines = $newIniLines
            }
        }
    }
    End {
    }
}
