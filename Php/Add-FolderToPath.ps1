Function Add-FolderToPath
{
    <#
    .Synopsis
    Adds a folder to the PATH environment variable

    .Parameter Path
    The path to the directory to be added to the PATH environment variable

    .Parameter Persist
    Permamently set the PATH for either the current user ('User') or for the whole system ('System')

    .Parameter CurrentProcess
    Specify this switch to add Path to the current PATH environment variable
    #>
    Param (
        [Parameter(Mandatory = $True, Position = 0, HelpMessage = 'The path to the directory to be added to the PATH environment variable')]
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
        $directorySeparatorChar = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd($directorySeparatorChar)
        $alternativePath = $Path + $directorySeparatorChar
        $targets = @()
        If ($CurrentProcess) {
            $targets += [System.EnvironmentVariableTarget]::Process
        }
        If ($Persist -ne $null) {
            If ($Persist -eq 'User') {
                $targets += [System.EnvironmentVariableTarget]::User
            } ElseIf ($Persist -eq 'System') {
                $targets += [System.EnvironmentVariableTarget]::Machine
            }
        }
        ForEach ($target in $targets) {
            $currentPathParts = [System.Environment]::GetEnvironmentVariable('Path', $target).Split($pathSeparator)
            $found = $currentPathParts | Where {$_ -eq $Path -or $_ -eq $alternativePath}
            if ($found -eq $null) {
                $currentPathParts += $Path
                $joinedPath = $currentPathParts -join $pathSeparator
                $requireRunAs = $false
                If ($target -eq [System.EnvironmentVariableTarget]::Machine) {
                    $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                    If (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
                        $requireRunAs = $true
                    }
                }
                If ($requireRunAs) {
                    $escapedJoinedPath = $joinedPath -replace "'", "''"
                    $exeCommand = "[System.Environment]::SetEnvironmentVariable('Path', '$escapedJoinedPath', [System.EnvironmentVariableTarget]::Machine)"
                    Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs
                } else {
                    [System.Environment]::SetEnvironmentVariable('Path', $joinedPath, $target)
                }
            }
        }
    }
    End {
    }
}
