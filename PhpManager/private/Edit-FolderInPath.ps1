function Edit-FolderInPath
{
    <#
    .Synopsis
    Adds or removes a folder to/from the PATH environment variable.

    .Parameter Operation
    The operation to be performed.

    .Parameter Path
    The path of the directory to be added to the PATH environment variable.

    .Parameter Persist
    When Operation is Add: permamently set the PATH for either the current user ('User') or for the whole system ('System').

    .Parameter CurrentProcess
    When Operation is Add: specify this switch to add Path to the current PATH environment variable.
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateSet('Add', 'Remove')]
        [string]$Operation,
        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('User', 'System')]
        [string]$Persist,
        [switch]$CurrentProcess
    )
    begin {
    }
    process {
        $pathSeparator = [System.IO.Path]::PathSeparator
        $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
        $Path = [System.IO.Path]::GetFullPath($Path).TrimEnd($directorySeparator)
        $alternativePath = $Path + $directorySeparator
        $needDirectRegistryAccess = [System.Environment]::GetEnvironmentVariable[0].OverloadDefinitions.Count -lt 2
        if ($Operation -eq 'Add') {
            $targets = @{}
            if ($CurrentProcess) {
                $targets[$Script:ENVTARGET_PROCESS] = $null
            }
            if ($Persist -eq 'User') {
                $targets[$Script:ENVTARGET_USER] = 'HKCU:\Environment'
            } elseif ($Persist -eq 'System') {
                $targets[$Script:ENVTARGET_MACHINE] = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
            }
        } else {
            $targets = @{
                $Script:ENVTARGET_PROCESS = $null
                $Script:ENVTARGET_USER = 'HKCU:\Environment'
                $Script:ENVTARGET_MACHINE = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
            }
        }
        $haveToBroadcast = $false
        foreach ($target in $targets.Keys) {
            if ($target -eq $Script:ENVTARGET_PROCESS) {
                $originalPath = $Env:Path
            } elseif ($needDirectRegistryAccess) {
                $originalPath = ''
                if (Test-Path -LiteralPath $targets[$target]) {
                    $pathProperties = Get-ItemProperty -LiteralPath $targets[$target] -Name 'Path'
                    if ($pathProperties | Get-Member -Name 'Path') {
                        $originalPath = $pathProperties.Path
                    }
                }
            } else {
                $originalPath = [System.Environment]::GetEnvironmentVariable('Path', $target)
            }
            if ($null -eq $originalPath -or $originalPath -eq '') {
                $parts = @()
            } else {
                $parts = $originalPath.Split($pathSeparator)
            }
            $newPath = $null
            if ($Operation -eq 'Add') {
                if (-Not($parts -icontains $Path -or $parts -icontains $alternativePath)) {
                    $parts += $Path
                    $newPath = $parts -join $pathSeparator
                }
            } elseif ($Operation -eq 'Remove') {
                $parts = $parts | Where-Object { $_ -ne $Path -and $_ -ne $alternativePath }
                $newPath = $parts -join $pathSeparator
            }
            if ($null -ne $newPath -and $newPath -ne $originalPath) {
                if ($target -eq $Script:ENVTARGET_USER -or $target -eq $Script:ENVTARGET_MACHINE) {
                    $haveToBroadcast = $true
                }
                Set-EnvVar -Name 'Path' -Value $newPath -Process $($target -eq $Script:ENVTARGET_PROCESS) -User $($target -eq $Script:ENVTARGET_USER) -Machine $($target -eq $Script:ENVTARGET_MACHINE) -NoBroadcast
            }
        }
        if ($needDirectRegistryAccess -and $haveToBroadcast) {
            try {
                Invoke-BroadcastEnvChanged
            } catch {
                Write-Debug -Message $_
            }
        }
    }
    end {
    }
}
