function Get-PhpIniKey
{
    <#
    .Synopsis
    Get the value of an entry in the php.ini file.

    .Parameter Key
    The key of the php.ini to get.

    .Parameter Path
    The path to a php.ini file, the path to a php.exe file or the folder containing php.exe.
    If omitted we'll use the one found in the PATH environment variable.

    .Example
    Get-PhpIniKey 'default_charset'

    .Example
    Get-PhpIniKey 'default_charset' 'C:\Dev\PHP\php.ini'

    .Example
    Get-PhpIniKey 'default_charset' 'C:\Dev\PHP'

    .Example
    Get-PhpIniKey 'default_charset' 'C:\Dev\PHP\php.exe'
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The key of the php.ini to get')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Key,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to a php.ini file, the path to a php.exe file or the folder containing php.exe; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    begin {
        $result = $null
    }
    process {
        $phpVersion = $null
        if ($null -eq $Path -or $Path -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
        } elseif ($Path -like '*.exe' -or (Test-Path -Path $Path -PathType Container)) {
            $phpVersion = [PhpVersionInstalled]::FromPath($Path)
        }
        if ($null -ne $phpVersion) {
            $iniPath = $phpVersion.IniPath
        } else {
            $iniPath = $Path
        }
        if ($Key -match '^\s*(zend_)?extension\s*$') {
            throw 'You can''t use this command to get the extensions'
        }
        $rxSearch = '^\s*' + [Regex]::Escape($Key) + '\s*=\s*(.*?)\s*$'
        foreach ($line in $(Get-PhpIniLine -Path $iniPath)) {
            $match = $line | Select-String -Pattern $rxSearch
            if ($match) {
                $result = $match.Matches[0].Groups[1].Value
            }
        }
    }
    end {
        $result
    }
}
