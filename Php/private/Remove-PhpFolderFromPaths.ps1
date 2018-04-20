Function Remove-PhpFolderFromPaths
{
    <#
    .Synopsis
    Removes a folder to the PATH environment variables (current process, current user, and system).

    .Parameter Path
    The path to the directory to be removed to the PATH environment variable.
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the directory to be removed to the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path
    )
    Begin {
    }
    Process {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd($directorySeparator)
        $alternativePath = $Path + $directorySeparator
        If ([System.Environment]::GetEnvironmentVariable[0].OverloadDefinitions.Count -lt 2) {
            Write-Warning "The current PowerShell version does not support saving environment variables for the User/Machine: we'll set the Path only for the current process"
            $targets = @(
                $Script:ENVTARGET_PROCESS
            )
        } Else {
            $targets = @(
                $Script:ENVTARGET_PROCESS,
                $Script:ENVTARGET_USER,
                $Script:ENVTARGET_MACHINE
            )
        }
        ForEach ($target in $targets) {
            If ($target -eq $Script:ENVTARGET_PROCESS) {
                $originalPath = $Env:Path
            } Else {
                $originalPath = [System.Environment]::GetEnvironmentVariable('Path', $target)
            }
            If ($originalPath) {
                $parts = $originalPath.Split($pathSeparator)
                $parts = $parts | Where-Object {$_ -ne $Path -and $_ -ne $alternativePath}
                $newPath = $parts -join $pathSeparator
                if ($originalPath -ne $newPath) {
                    $requireRunAs = $false
                    If ($target -eq $Script:ENVTARGET_MACHINE) {
                        $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                        If (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
                            $requireRunAs = $true
                        }
                    }
                    If ($requireRunAs) {
                        $escapedNewPath = $newPath -replace "'", "''"
                        $exeCommand = "[System.Environment]::SetEnvironmentVariable('Path', '$escapedNewPath', '$Script:ENVTARGET_MACHINE')"
                        Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs
                    } Else {
                        If ($target -eq $Script:ENVTARGET_PROCESS) {
                            $Env:Path = $newPath
                        } Else {
                            [System.Environment]::SetEnvironmentVariable('Path', $newPath, $target)
                        }
                    }
                }
            }
        }
    }
    End {
    }
}
