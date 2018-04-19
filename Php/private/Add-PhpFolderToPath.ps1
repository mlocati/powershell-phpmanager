Function Add-PhpFolderToPath
{
    <#
    .Synopsis
    Adds a folder to the PATH environment variable.

    .Parameter Path
    The path of the directory to be added to the PATH environment variable.

    .Parameter Persist
    Permamently set the PATH for either the current user ('User') or for the whole system ('System').

    .Parameter CurrentProcess
    Specify this switch to add Path to the current PATH environment variable.
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path of the directory to be added to the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $False, Position = 1, HelpMessage = 'Permamently set the PATH for either the current user (''User'') or for the whole system (''System'')')]
        [ValidateSet('User', 'System')]
        [string]$Persist,
        [switch]$CurrentProcess
    )
    Begin {
    }
    Process {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd($directorySeparator)
        $alternativePath = $Path + $directorySeparator
        $targets = @()
        If ($CurrentProcess) {
            $targets += $Script:ENVTARGET_PROCESS
        }
        If ($Persist -ne $null) {
            If ($Persist -eq 'User') {
                $targets += $Script:ENVTARGET_USER
            } ElseIf ($Persist -eq 'System') {
                $targets += $Script:ENVTARGET_MACHINE
            }
        }
        ForEach ($target in $targets) {
            If ($target -eq $Script:ENVTARGET_PROCESS) {
                $currentPath = $Env:Path
            } Else {
                $currentPath = [System.Environment]::GetEnvironmentVariable('Path', $target).Split($pathSeparator)
            }
            $currentPathParts = $currentPath.Split($pathSeparator)
            $found = $currentPathParts | Where-Object {$_ -eq $Path -or $_ -eq $alternativePath}
            if ($found -eq $null) {
                $currentPathParts += $Path
                $joinedPath = $currentPathParts -join $pathSeparator
                $requireRunAs = $false
                If ($target -eq $Script:ENVTARGET_MACHINE) {
                    $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                    If (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
                        $requireRunAs = $true
                    }
                }
                If ($requireRunAs) {
                    $escapedJoinedPath = $joinedPath -replace "'", "''"
                    $exeCommand = "[System.Environment]::SetEnvironmentVariable('Path', '$escapedJoinedPath', '$Script:ENVTARGET_MACHINE')"
                    Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs
                } else {
                    If ($target -eq $Script:ENVTARGET_PROCESS) {
                        $Env:Path = $joinedPath
                    } Else {
                        [System.Environment]::SetEnvironmentVariable('Path', $joinedPath, $target)
                    }
                }
            }
        }
    }
    End {
    }
}
