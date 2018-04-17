Function Get-PhpVersionFromExecutable
{
    <#
    .Synopsis
    Creates a new object representing a PHP version from a PHP executable.
    
    .Parameter ExecutablePath
    The path to the PHP executable

    .Outputs
    PSCustomObject

    .Example
    Get-PhpVersionFromExecutable 'C:\Dev\PHP\php.exe'
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the PHP executable')]
        [ValidateNotNull()]
        [string]$ExecutablePath
    )
    Begin {
        $data = @{}
    }
    Process {
        $exeParameters = @('-r', 'echo PHP_VERSION, ''@'', PHP_INT_SIZE * 8;')
        $exeResult = & $ExecutablePath $exeParameters
        $rxMatch = $exeResult | Select-String -Pattern '^(\d+\.\d+\.\d+)(?:RC(\d+))?@(\d+)$'
        $data['BaseVersion'] = $rxMatch.Matches.Groups[1].Value
        $data['RC'] = $rxMatch.Matches.Groups[2].Value
        $data['Architecture'] = Get-Variable -Name $('ARCHITECTURE_' + $rxMatch.Matches.Groups[3].Value + 'BITS') -ValueOnly -Scope Script
        $exeParameters = @('-i')
        $exeResult = & $ExecutablePath $exeParameters
        $rxMatch = $exeResult | Select-String -CaseSensitive -Pattern '^Thread Safety\s*=>\s*(\w+)'
        $data['ThreadSafe'] = $rxMatch.Matches.Groups[1].Value -eq 'enabled'
        $rxMatch = $exeResult | Select-String -CaseSensitive -Pattern '^Compiler\s*=>\s*MSVC([\d]{1,2})'
        $data['VCVersion'] = $rxMatch.Matches.Groups[1].Value
        $data['ExePath'] = [System.IO.Path]::GetFullPath($ExecutablePath)
    }
    End {
        New-PhpVersion $data
    }
}
