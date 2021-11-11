function Install-PhpExtensionPrerequisite() {
    <#
    .Synopsis
    Installs the prerequisites of PHP extensions.

    .Parameter Extension
    The name (or the handle) of the PHP extension(s) to be disabled.

    .Parameter InstallPath
    The path to a directory where the prerequisites should be installed (it should be in your PATH environment variable).
    If omitted we'll install the dependencies in the PHP directory.

    .Parameter PhpPath
    The path to the PHP installation.
    If omitted we'll use the one found in the PATH environment variable.

    .Example
    Install-PhpExtensionPrerequisite imagick,zip
    #>
    [OutputType()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'The name (or the handle) of the PHP extension(s) to be disabled')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string[]] $Extension,
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'The path to a directory where the prerequisites should be installed (it should be in your PATH environment variable); if omitted we''ll install the dependencies in the PHP directory')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $InstallPath,
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = 'The path to the PHP installation; if omitted we''ll use the one found in the PATH environment variable')]
        [ValidateNotNull()]
        [ValidateLength(1, [int]::MaxValue)]
        [string] $PhpPath
    )
    begin {
    }
    process {
        if ($null -eq $PhpPath -or $PhpPath -eq '') {
            $phpVersion = [PhpVersionInstalled]::FromEnvironmentOne()
            Write-Verbose "Using PHP found in $($phpVersion.ActualFolder)"
        } else {
            $phpVersion = [PhpVersionInstalled]::FromPath($PhpPath)
        }
        if ($null -eq $InstallPath -or $InstallPath -eq '') {
            $InstallPath = $phpVersion.ActualFolder
        } elseif (-not(Test-Path -LiteralPath $InstallPath -PathType Container)) {
            throw "The directory $InstallPath does not exist"
        }
        foreach ($wantedExtension in $Extension) {
            $wantedExtensionHandle = Get-PhpExtensionHandle -Name $wantedExtension
            Write-Verbose "Checking prerequisites for $wantedExtensionHandle"
            switch ($wantedExtensionHandle) {
                default {
                    Write-Verbose "No prerequisites needed for $wantedExtensionHandle"
                }
            }
        }
    }
    end {
    }
}
