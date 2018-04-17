Function Remove-FolderFromPaths
{
    <#
    .Synopsis
    Removes a folder to the PATH environment variables (current process, current user, and system)

    .Parameter Path
    The path to the directory to be removed to the PATH environment variable
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
        $directorySeparatorChar = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd($directorySeparatorChar)
        $alternativePath = $Path + $directorySeparatorChar
        $targets = @(
            [System.EnvironmentVariableTarget]::Process,
            [System.EnvironmentVariableTarget]::User,
            [System.EnvironmentVariableTarget]::Machine
        )
        ForEach ($target in $targets) {
            $originalPath = [System.Environment]::GetEnvironmentVariable('Path', $target)
            $parts = $originalPath.Split($pathSeparator)
            $parts = $parts | Where {$_ -ne $Path -and $_ -ne $alternativePath}
            $newPath = $parts -join $pathSeparator
            if ($originalPath -ne $newPath) {
                $requireRunAs = $false
                If ($target -eq [System.EnvironmentVariableTarget]::Machine) {
                    $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                    If (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
                        $requireRunAs = $true
                    }
                }
                If ($requireRunAs) {
                    $escapedNewPath = $newPath -replace "'", "''"
                    $exeCommand = "[System.Environment]::SetEnvironmentVariable('Path', '$escapedNewPath', [System.EnvironmentVariableTarget]::Machine)"
                    Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs
                } Else {
                    [System.Environment]::SetEnvironmentVariable('Path', $newPath, $target)
                }
            }
        }
    }
    End {
    }
}
