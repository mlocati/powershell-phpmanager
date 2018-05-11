function Get-PhpExtensionDetail
{
    <#
    .Synopsis
    Inspects files containing PHP extensions.

    .Parameter PhpVersion
    The instance of PhpVersion for which you want to inspect the extension(s).

    .Parameter Path
    The path of the PHP extension file, or a directory with possible extension files.
    If omitted we'll inspect all the extensions in the extension directory of PhpVersion.

    .Outputs
    System.Array|PSObject

    .Example
    Get-PhpExtensionDetail -PhpVersion $phpVersion -Path 'C:\Dev\PHP\ext\php_ext.dll'
    #>
    [OutputType([psobject])]
    [OutputType([psobject[]])]
    param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want to inspect the extension(s)')]
        [ValidateNotNull()]
        [PhpVersionInstalled]$PhpVersion,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'The path of the PHP extension file, or a directory with possible extension files; if omitted we''ll inspect all the extensions in the extension directory of PhpVersion')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    begin {
        $result = $null
    }
    process {
        $inspectorParameters = @()
        if ($null -ne $Path -and $Path -ne '' -and (Test-Path -Path $Path -PathType Leaf)) {
            $result = $null
            $inspectingSingleFile = $true
            $inspectorParameters += $Path
            $somethingToInspect = $true
        } else {
            $result = @()
            $inspectingSingleFile = $false
            if ($null -eq $Path -or $Path -eq '') {
                $folder = $PhpVersion.ExtensionsPath
            } else {
                $folder = $Path
                if (-Not(Test-Path -Path $folder -PathType Container)) {
                    throw "Unable to find the file/folder $folder"
                }
            }
            if (Test-Path -Path $folder -PathType Container) {
                $subFiles = Get-ChildItem -Path $folder -Filter '*.dll' | Select-Object -ExpandProperty 'FullName'
                $somethingToInspect = $subFiles.Count -gt 0
                if ($somethingToInspect) {
                    $inspectorParameters += $subFiles
                }
            } else {
                $somethingToInspect = $false
            }
        }
        if ($somethingToInspect) {
            $rxGood = '^'
            $rxGood += 'php:(?:' + $PhpVersion.ComparableVersion.Major + '\.' + $PhpVersion.ComparableVersion.Minor + '(?:\.\d+)*)?'
            $rxGood += '\tarchitecture:' + $PhpVersion.Architecture
            $rxGood += '\tthreadSafe:(?:' + ([int]$PhpVersion.ThreadSafe) + ')?'
            $rxGood += '\ttype:(Php|Zend)'
            $rxGood += '\tname:(.+)'
            $rxGood += '\tversion:(.*)'
            $rxGood += '\tfilename:(.+)'
            $rxGood += '$'
            $inspectorPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', 'Inspect-PhpExtension-' + $PhpVersion.Architecture + '.exe')
            $inspectorResults = & $inspectorPath $inspectorParameters
            if ($LASTEXITCODE -ne 0) {
                throw 'Failed to inspect extension(s)'
            }
            foreach ($inspectorResult in $inspectorResults) {
                $match = $inspectorResult | Select-String -Pattern $rxGood
                if (-Not($match)) {
                    if ($inspectingSingleFile) {
                        throw "Failed to inspect extension: $inspectorResult"
                    }
                } else {
                    $result1 = [PhpExtension]::new(@{
                        'Type' = $match.Matches.Groups[1].Value;
                        'State' = $Script:EXTENSIONSTATE_UNKNOWN;
                        'Name' = $match.Matches.Groups[2].Value;
                        'Handle' = Get-PhpExtensionHandle -Name $match.Matches.Groups[2].Value;
                        'Version' = $match.Matches.Groups[3].Value;
                        'Filename' = $match.Matches.Groups[4].Value;
                    })
                    if ($inspectingSingleFile) {
                        $result = $result1;
                    } else {
                        $result += $result1;
                    }
                }
            }
        }
    }
    end {
        $result
    }
}
