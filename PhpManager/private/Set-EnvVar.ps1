function Set-EnvVar() {
    <#
    .Synopsis
    Set an environment variable, for the current process/user/machine

    .Parameter Name
    The name of the environment variable

    .Parameter Value
    The value of the environment variable

    .Parameter Process
    Update the environment variable for the current process?

    .Parameter User
    Update the environment variable for the current user?

    .Parameter Machine
    Update the environment variable for the local machine?
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $Name,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Value,
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [bool] $Process = $false,
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNull()]
        [bool] $User = $false,
        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateNotNull()]
        [bool] $Machine = $false,
        [switch] $NoBroadcast
    )
    begin {
    }
    process {
        if ($null -eq $Value) {
            $Value = ''
        }
        If ($Process) {
            New-Item -Path Env: -Name $Name -Value $Value -Force | Out-Null
        }
        if (-not($User -or $Machine)) {
            return;
        }
        $needDirectRegistryAccess = [System.Environment]::GetEnvironmentVariable[0].OverloadDefinitions.Count -lt 2
        if ($User) {
            if ($needDirectRegistryAccess) {
                New-ItemProperty -Path 'HKCU:\Environment' -Name $Name -Value $Value -PropertyType ExpandString -Force | Out-Null
            } else {
                [System.Environment]::SetEnvironmentVariable($Name, $Value, 'User') | Out-Null
            }
        }
        if ($Machine) {
            $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
            if ($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
                if ($needDirectRegistryAccess) {
                    New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name $Name -Value $Value -PropertyType ExpandString -Force | Out-Null
                } else {
                    [System.Environment]::SetEnvironmentVariable($Name, $Value, 'Machine') | Out-Null
                }
            } else {
                $NameEscaped = $Name -replace "'", "''"
                $ValueEscaped = $Value -replace "'", "''"
                if ($needDirectRegistryAccess) {
                    $exeCommand = "New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' -Name '$NameEscaped' -Value '$ValueEscaped' -PropertyType ExpandString -Force | Out-Null"
                } else {
                    $exeCommand = "[System.Environment]::SetEnvironmentVariable('$NameEscaped', '$ValueEscaped', 'Machine') | Out-Null"
                }
                Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -WindowStyle Hidden -Verb RunAs -Wait
            }
        }
        if ($needDirectRegistryAccess -and -not($NoBroadcast)) {
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
