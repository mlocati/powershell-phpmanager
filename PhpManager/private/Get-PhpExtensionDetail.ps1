function Get-PhpExtensionDetail
{
    <#
    .Synopsis
    Inspects files containing PHP extensions.

    .Parameter PhpVersion
    The instance of PhpVersion for which you want to inspect the extension(s).
    It can be omitted.

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
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The instance of PhpVersion for which you want to inspect the extension(s). If omitted you have to specify the -Path parameter.')]
        [PhpVersionInstalled]$PhpVersion,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path of the PHP extension file, or a directory with possible extension files; if omitted we''ll inspect all the extensions in the extension directory of PhpVersion')]
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
        } elseif ($null -eq $PhpVersion) {
            throw "Both -PhpVersion and -Path parameters are empty, or -PhpVersion is empty and -Path is not the path of a file"
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
            $rxIndex = 0
            $groups = @{}
            $rxGood = '^'
            $rxGood += 'php:((?:'
            if ($null -eq $PhpVersion) {
                $rxGood += '\d+\.\d+(?:\.\d+)*'
            } else {
                $rxGood += '' + $PhpVersion.ComparableVersion.Major + '\.' + $PhpVersion.ComparableVersion.Minor + '(?:\.\d+)*'
            }
            $rxGood += ')?)'
            $groups['phpVersion'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'architecture:('
            if ($null -eq $PhpVersion) {
                $checkArchitectures = @($Script:ARCHITECTURE_32BITS, $Script:ARCHITECTURE_64BITS)
                $rxGood += $Script:ARCHITECTURE_32BITS + '|' + $Script:ARCHITECTURE_64BITS
            } else {
                $checkArchitectures = @($PhpVersion.Architecture)
                $rxGood += $PhpVersion.Architecture
            }
            $rxGood += ')'
            $groups['architecture'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'threadSafe:((?:'
            if ($null -eq $PhpVersion) {
                $rxGood += '0|1'
            } else {
                $rxGood += [int]$PhpVersion.ThreadSafe
            }
            $rxGood += ')?)'
            $groups['threadSafe'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'type:(Php|Zend)'
            $groups['type'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'name:(.+)'
            $groups['name'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'version:(.*)'
            $groups['version'] = ++$rxIndex
            $rxGood += '\t';
            $rxGood += 'filename:(.+)'
            $groups['filename'] = ++$rxIndex
            $rxGood += '$'
            foreach ($checkArchitecture in $checkArchitectures) {
                $inspectorPath = [System.IO.Path]::Combine($PSScriptRoot, 'bin', 'Inspect-PhpExtension-' + $checkArchitecture + '.exe')
                $inspectorResults = & $inspectorPath $inspectorParameters
                if ($inspectorResults -ne 'Unable to open the DLL.') {
                    if ($LASTEXITCODE -eq 0) {
                        break
                    }
                    throw 'Failed to inspect extension(s)'
                }
            }
            foreach ($inspectorResult in $inspectorResults) {
                $match = $inspectorResult | Select-String -Pattern $rxGood
                if (-Not($match)) {
                    if ($inspectingSingleFile) {
                        throw "Failed to inspect extension: $inspectorResult"
                    }
                } else {
                    $result1 = [PhpExtension]::new(@{
                        'Type' = $match.Matches.Groups[$groups['type']].Value;
                        'State' = $Script:EXTENSIONSTATE_UNKNOWN;
                        'Name' = $match.Matches.Groups[$groups['name']].Value;
                        'Handle' = Get-PhpExtensionHandle -Name $match.Matches.Groups[$groups['name']].Value;
                        'Version' = $match.Matches.Groups[$groups['version']].Value;
                        'Filename' = $match.Matches.Groups[$groups['filename']].Value;
                        'PhpVersion' = $match.Matches.Groups[$groups['phpVersion']].Value;
                        'Architecture' = $match.Matches.Groups[$groups['architecture']].Value;
                        'ThreadSafe' = $match.Matches.Groups[$groups['threadSafe']].Value;
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
