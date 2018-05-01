Function Edit-PhpFolderInPath
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
    Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [ValidateNotNull()]
        [ValidateSet('Add', 'Remove')]
        [string]$Operation,
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string]$Path,
        [Parameter(Mandatory = $False, Position = 2)]
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
        $needDirectRegistryAccess = [System.Environment]::GetEnvironmentVariable[0].OverloadDefinitions.Count -lt 2
        If ($Operation -eq 'Add') {
            $targets = @{}
            If ($CurrentProcess) {
                $targets[$Script:ENVTARGET_PROCESS] = $null
            }
            If ($Persist -eq 'User') {
                $targets[$Script:ENVTARGET_USER] = 'HKCU:\Environment'
            } ElseIf ($Persist -eq 'System') {
                $targets[$Script:ENVTARGET_MACHINE] = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
            }
        } Else {
            $targets = @{
                $Script:ENVTARGET_PROCESS = $null
                $Script:ENVTARGET_USER = 'HKCU:\Environment'
                $Script:ENVTARGET_MACHINE = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'
            }
        }
        $haveToBroadcast = $false
        ForEach ($target in $targets.Keys) {
            If ($target -eq $Script:ENVTARGET_PROCESS) {
                $originalPath = $Env:Path
            } ElseIf ($needDirectRegistryAccess) {
                $originalPath = ''
                If (Test-Path -LiteralPath $targets[$target]) {
                    $pathProperties = Get-ItemProperty -LiteralPath $targets[$target] -Name 'Path'
                    If ($pathProperties | Get-Member -Name 'Path') {
                        $originalPath = $pathProperties.Path
                    }
                }
            } Else {
                $originalPath = [System.Environment]::GetEnvironmentVariable('Path', $target)
            }
            If ($null -eq $originalPath -or $originalPath -eq '') {
                $parts = @()
            } Else {
                $parts = $originalPath.Split($pathSeparator)
            }
            $newPath = $null
            If ($Operation -eq 'Add') {
                If (-Not($parts -icontains $Path -or $parts -icontains $alternativePath)) {
                    $parts += $Path
                    $newPath = $parts -join $pathSeparator
                }
            } ElseIf ($Operation -eq 'Remove') {
                $parts = $parts | Where-Object {$_ -ne $Path -and $_ -ne $alternativePath}
                $newPath = $parts -join $pathSeparator
            }
            If ($null -ne $newPath -and $newPath -ne $originalPath) {
                If ($target -eq $Script:ENVTARGET_PROCESS) {
                    $Env:Path = $newPath
                } Else {
                    $requireRunAs = $false
                    If ($target -eq $Script:ENVTARGET_MACHINE) {
                        $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
                        If (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
                            $requireRunAs = $true
                        }
                    }
                    If ($requireRunAs) {
                        $newPathEscaped = $newPath -replace "'", "''"
                        If ($needDirectRegistryAccess) {
                            $exeCommand = "New-ItemProperty -Path '$($targets[$target])' -Name 'Path' -Value '$newPathEscaped' -PropertyType ExpandString -Force | Out-Null"
                        } Else {
                            $exeCommand = "[System.Environment]::SetEnvironmentVariable('Path', '$newPathEscaped', '$Script:ENVTARGET_MACHINE') | Out-Null"
                        }
                        Start-Process -FilePath 'powershell.exe' -ArgumentList "-Command ""$exeCommand""" -Verb RunAs
                    } else {
                        If ($needDirectRegistryAccess) {
                            New-ItemProperty -Path $targets[$target] -Name 'Path' -Value $newPath -PropertyType ExpandString -Force | Out-Null
                        } Else {
                            [System.Environment]::SetEnvironmentVariable('Path', $newPath, $target) | Out-Null
                        }
                    }
                    $haveToBroadcast = $True
                }
            }
        }
        If ($haveToBroadcast) {
            Try {
                $className = 'PhpManager_Env_Broadcaster_v1'
                $classType = ([System.Management.Automation.PSTypeName]$className).Type
                If ($null -eq $classType) {
                    Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public sealed class $className
{
    /// <summary>
    /// Send the message to all top-level windows in the system, including disabled or invisible unowned windows.
    /// </summary>
    private const int HWND_BROADCAST = 0xffff;

    /// <summary>
    /// Possible messages to be sent.
    /// </summary>
    private enum SmtoMsg : uint
    {
        /// <summary>
        /// A message that is sent to all top-level windows when the SystemParametersInfo function changes a system-wide setting or when policy settings have changed.
        /// </summary>
        WM_SETTINGCHANGE = 0x001A,
    }

    /// <summary>
    /// Possible flags of the SendMessageTimeout function
    /// </summary>
    [Flags]
    private enum SmtoFlags : uint
    {
        /// <summary>
        /// The function returns without waiting for the time-out period to elapse if the receiving thread appears to not respond or "hangs."
        /// </summary>
        SMTO_ABORTIFHUNG = 0x0002,
        /// <summary>
        /// Prevents the calling thread from processing any other requests until the function returns.
        /// </summary>
        SMTO_BLOCK = 0x0001,
        /// <summary>
        /// The calling thread is not prevented from processing other requests while waiting for the function to return.
        /// </summary>
        SMTO_NORMAL = 0x0000,
        /// <summary>
        /// The function does not enforce the time-out period as long as the receiving thread is processing messages.
        /// </summary>
        SMTO_NOTIMEOUTIFNOTHUNG = 0x0008,
        /// <summary>
        /// The function should return 0 if the receiving window is destroyed or its owning thread dies while the message is being processed.
        /// </summary>
        SMTO_ERRORONEXIT = 0x0020,
    }

    /// <summary>
    /// Sends the specified message to one or more windows.
    /// </summary>
    /// <param name="hWnd">A handle to the window whose window procedure will receive the message.</param>
    /// <param name="Msg">The message to be sent.</param>
    /// <param name="wParam">Any additional message-specific information.</param>
    /// <param name="lParam">Any additional message-specific information.</param>
    /// <param name="fuFlags">The behavior of this function.</param>
    /// <param name="uTimeout">The duration of the time-out period, in milliseconds.</param>
    /// <param name="lpdwResult">The result of the message processing.</param>
    /// <returns>If the function fails or times out, the return value is 0.</returns>
    [DllImport("user32.dll", BestFitMapping = false, ThrowOnUnmappableChar = true, SetLastError = true)]
    private static extern IntPtr SendMessageTimeout(IntPtr hWnd, UInt32 Msg, IntPtr wParam, String lParam, UInt32 fuFlags, UInt32 uTimeout, IntPtr lpdwResult);

    /// <summary>
    /// Broadcasts a "Environment settings changed" message.
    /// </summary>
    /// <exception cref="System.TimeoutException">Throws a TimeoutException when the message timed out.</exception>
    /// <exception cref="System.System.ComponentModel.Win32Exception">Throws a Win32Exception when the function fails.</exception>
    public static void BroadcastEnvironmentChange()
    {
        IntPtr lResult = SendMessageTimeout(new IntPtr(HWND_BROADCAST), (UInt32)SmtoMsg.WM_SETTINGCHANGE, IntPtr.Zero, "Environment", (UInt32)SmtoFlags.SMTO_ABORTIFHUNG, 1000, IntPtr.Zero);
        if (lResult == IntPtr.Zero)
        {
            int rc = Marshal.GetLastWin32Error();
            if (rc == 0)
            {
                throw new TimeoutException("SendMessageTimeout() timed out");
            }
            throw new Win32Exception(rc);
        }
    }
}
"@
                    $classType = ([System.Management.Automation.PSTypeName]$className).Type
                }
                $classType.GetMethod('BroadcastEnvironmentChange').Invoke($null, @())
            }
            Catch {
                Write-Debug -Message $_
            }
        }
    }
    End {
    }
}
