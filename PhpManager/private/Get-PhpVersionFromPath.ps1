Function Get-PhpVersionFromPath
{
    <#
    .Synopsis
    Creates a new object representing a PHP version from a PHP executable.

    .Parameter Path
    The path to the PHP executable (or to the folder containing it).

    .Outputs
    PSCustomObject

    .Example
    Get-PhpVersionFromPath -Path 'C:\Dev\PHP\php.exe'

    .Example
    Get-PhpVersionFromPath -Path 'C:\Dev\PHP'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the PHP executable (or to the folder containing it)')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    Begin {
        $data = @{}
    }
    Process {
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path)
        If (Test-Path -Path $Path -PathType Leaf) {
            $executablePath = $Path
            $folder = [System.IO.Path]::GetDirectoryName($executablePath)
        } ElseIf (Test-Path -Path $Path -PathType Container) {
            $folder = $Path
            $executablePath = [System.IO.Path]::Combine($folder, 'php.exe')
            If (-Not(Test-Path -Path $executablePath -PathType Leaf)) {
                throw "Unable to find the file $executablePath"
            }
        } Else {
            throw "Unable to find the file/folder $Path"
        }
        $data['ExecutablePath'] = $executablePath
        $executableParameters = @('-n', '-r', 'echo PHP_VERSION, ''@'', PHP_INT_SIZE * 8;')
        $executableResult = & $executablePath $executableParameters
        $match = $executableResult | Select-String -Pattern '^(\d+\.\d+\.\d+)(?:RC(\d+))?@(\d+)$'
        $data['BaseVersion'] = $match.Matches.Groups[1].Value
        $data['RC'] = $match.Matches.Groups[2].Value
        $data['Architecture'] = Get-Variable -Scope Script -ValueOnly -Name $('ARCHITECTURE_' + $match.Matches.Groups[3].Value + 'BITS')
        $executableParameters = @('-i')
        $executableResult = & $executablePath $executableParameters
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Thread Safety\s*=>\s*(\w+)'
        $data['ThreadSafe'] = $match.Matches.Groups[1].Value -eq 'enabled'
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Compiler\s*=>\s*MSVC([\d]{1,2})'
        If ($null -eq $match) {
            $v = [System.Version]$data['BaseVersion']
            If ($v -le [System.Version]'5.2.9999') {
                $data['VCVersion'] = 6
            } Else {
                Throw 'Failed to recognize VCVersion'
            }
        } Else {
            $data['VCVersion'] = $match.Matches.Groups[1].Value
        }
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*Loaded Configuration File\s*=>\s*([\S].*[\S])\s*$'
        $iniPath = ''
        If ($match) {
            $iniPath = $match.Matches.Groups[1].Value
            If ($iniPath -eq '(none)') {
                $iniPath = ''
            } Else {
                $iniPath = $iniPath.Replace('/', $directorySeparator)
                $iniPath = [System.IO.Path]::Combine($folder, $iniPath)
            }
        }
        If ($iniPath -eq '') {
            $iniPath = [System.IO.Path]::Combine($folder, 'php.ini')
        }
        $data['IniPath'] = $iniPath
        $match = $executableResult | Select-String -CaseSensitive -Pattern '^[ \t]*extension_dir\s*=>\s*([\S].*[\S])\s*=>'
        $extensionsPath = ''
        If ($match) {
            $extensionsPath = $match.Matches.Groups[1].Value
            If ($extensionsPath -eq '(none)') {
                $extensionsPath = ''
            } Else {
                $extensionsPath = $extensionsPath.Replace('/', $directorySeparator)
                $extensionsPath = [System.IO.Path]::Combine($folder, $extensionsPath)
                $extensionsPath = $extensionsPath -replace [regex]::Escape("$directorySeparator.$directorySeparator"), $directorySeparator
            }
        }
        $data['ExtensionsPath'] = $extensionsPath
    }
    End {
        New-PhpVersion $data
    }
}
