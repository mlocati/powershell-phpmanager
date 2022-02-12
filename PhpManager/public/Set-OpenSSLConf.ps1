function Set-OpenSSLConf
{
    <#
    .Synopsis
    Persist/fix the path of the openssl.cnf file by settng the OPENSSL_CONF environment variable

    .Parameter Path
    The path to the openssl.cnf file (if not provided we'll try to detect it)

    .Parameter Target
    'Process' [default] to set the OPENSSL_CONF environment variable for the current process only
    'User' to set the OPENSSL_CONF environment variable for the current process and the current user
    'Machine' to set the OPENSSL_CONF environment variable for the current process and the local machine

    .Example
    Set-OpenSSLConf C:\Path\to\openssl.cnf
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'The path of openssl.cnf')]
        [string] $Path,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The target level of the OPENSSL_CONF environment variable to be set')]
        [ValidateNotNull()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string] $Target = 'Process'
    )
    begin {
    }
    process {
        if ($null -eq $Path -or $Path -eq '') {
            $searchPaths = @(
                $Env:OPENSSL_CONF,
                $Env:SSLEAY_CONF,
                "${Env:CommonProgramFiles}\SSL\openssl.cnf" + '',
                "${Env:CommonProgramFiles(x86)}\SSL\openssl.cnf"
            )
            foreach ($php in Get-Php) {
                $searchPaths += "$($php.Folder)\extras\ssl\openssl.cnf"
                $searchPaths += "$($php.Folder)\extras\openssl\openssl.cnf"
                $searchPaths += "$($php.Folder)\extras\openssl.cnf"
            }
            $absolutePath = ''
            foreach ($searchPath in $searchPaths) {
                if (-not($searchPath) -or -not(Test-Path -LiteralPath $searchPath)) {
                    continue
                }
                $searchPath = $(Resolve-Path -LiteralPath $searchPath).Path
                if (Test-Path -LiteralPath $searchPath -PathType Leaf) {
                    $absolutePath = $searchPath
                    break
                }
            }
            if ($absolutePath -eq '') {
                throw 'Unable to find openssl.cnf'
                return
            }
            Write-Verbose "openssl.cnf found at $absolutePath"
        } else {
            if (Test-Path -LiteralPath $Path -PathType Container) {
                $tmp = Join-Path -Path $Path -ChildPath 'openssl.cnf'
                if (-not(Test-Path -LiteralPath $tmp -PathType Leaf)) {
                    throw "The folder $Path does not contain the file openssl.cnf"
                    return;
                }
                $Path = $tmp
            } elseif (-not(Test-Path -LiteralPath $Path -PathType Leaf)) {
                throw "Unable to find the file or directory $Path"
                return;
            }
            $absolutePath = $(Resolve-Path -LiteralPath $Path).Path
        }
        $Env:OPENSSL_CONF = $absolutePath
        if ($Target -eq 'User') {
            Set-EnvVar -Name 'OPENSSL_CONF' -Value $absolutePath -User $true
        } elseif ($Target -eq 'Machine') {
            Set-EnvVar -Name 'OPENSSL_CONF' -Value $absolutePath -Machine $true
        }
    }
    end {
    }
}
