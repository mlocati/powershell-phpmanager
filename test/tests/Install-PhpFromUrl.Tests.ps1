Describe 'Install-PhpFromUrl' {
    $testCases = @(
        @{supportsPath = $true}
        @{supportsPath = $false}
    )
    It 'should install VcRedist with Path supported=<supportsPath>' -TestCases $testCases {
        param ($supportsPath)

        $currentUser = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if (-Not($currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))) {
            Set-ItResult -Skipped -Because 'this test requires administrator privileges'
        }
        $phpPath = Join-Path -Path TestDrive: -ChildPath PHP
        $runtimePath = Join-Path -Path $TestDrive -ChildPath "Runtime's files"
        $previousExitCode = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        & (Get-Module PhpManager) {
            param ($phpPath, $supportsPath)
            $exePath = Join-Path -Path $phpPath -ChildPath php.exe
            # Force STATUS_DLL_NOT_FOUND even when the runtime is already installed.
            Set-Item -LiteralPath "Function:script:$exePath" -Value { $global:LASTEXITCODE = -1073741515 }
            function script:Get-VcList {
                param ($Export)
                if ($Export -eq 'All') {
                    return [pscustomobject]@{Release = '2012'; Architecture = 'x86'}
                }
            }
            function script:Save-VcRedist {
                param ([Parameter(ValueFromPipeline = $true)] $VcList, $Path)
                $VcList | Add-Member -MemberType NoteProperty -Name Path -Value (Join-Path -Path $Path -ChildPath vcredist_x86.exe)
            }
            # Exercise real parameter discovery and binding for both signatures.
            $pathParameter = if ($supportsPath) { ', [Parameter(Mandatory = $true)] [string] $Path' } else { '' }
            Set-Item -LiteralPath Function:script:Install-VcRedist -Value ([scriptblock]::Create(@"
[CmdletBinding()]
param ([Parameter(ValueFromPipeline = `$true)] `$VcList$pathParameter)
process { return `$PSBoundParameters }
"@))
        } $phpPath $supportsPath

        Mock -ModuleName PhpManager Get-FileFromUrlOrCache {
            $archive = New-Item -Path (Join-Path -Path $TestDrive -ChildPath php.zip) -ItemType File -Force
            return $archive.FullName, $true
        }
        Mock -ModuleName PhpManager New-TempDirectory {
            $path = Join-Path -Path TestDrive: -ChildPath PHP
            if (Test-Path -LiteralPath $path) {
                $path = Join-Path -Path $TestDrive -ChildPath "Runtime's files"
            }
            New-Item -Path $path -ItemType Directory | Out-Null
            return $path
        }
        Mock -ModuleName PhpManager Expand-ArchiveWith7Zip {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $DestinationPath -ChildPath php.exe) -ItemType File -Force | Out-Null
        }
        Mock -ModuleName PhpManager Get-Module { return [pscustomobject]@{Version = [version]'4.1.527'} } -ParameterFilter { $Name -eq 'VcRedist' }
        try {
            $result = & (Get-Module PhpManager) {
                param ($path)
                $url = 'https://www.example.com/php-5.6.40-nts-Win32-VC11-x86.zip'
                $version = Get-PhpVersionFromUrl -Url $url -ReleaseState Release
                Install-PhpFromUrl -Url $url -Path $path -PhpVersion $version -InstallVCRedist $true
            } (Join-Path -Path $TestDrive -ChildPath installed)
            @($result).Count | Should -Be 1
            $result.ContainsKey('Path') | Should -BeExactly $supportsPath
            if ($supportsPath) {
                $result.Path | Should -BeExactly $runtimePath
            }
            $result.VcList.Path | Should -BeExactly (Join-Path -Path $runtimePath -ChildPath vcredist_x86.exe)
            $result.VcList.Release | Should -BeExactly '2012'
            $result.VcList.Architecture | Should -BeExactly 'x86'
        } finally {
            & (Get-Module PhpManager) {
                param ($phpPath)
                foreach ($name in @('Get-VcList', 'Save-VcRedist', 'Install-VcRedist', (Join-Path -Path $phpPath -ChildPath php.exe))) {
                    Remove-Item -LiteralPath "Function:$name"
                }
            } $phpPath
            if ($null -ne $previousExitCode) {
                $global:LASTEXITCODE = $previousExitCode
            } else {
                Remove-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
            }
        }
    }
    It 'should preserve VcRedist metadata when elevating with Path supported=<supportsPath>' -TestCases $testCases {
        param ($supportsPath)

        $runtimePath = Join-Path -Path $TestDrive -ChildPath "Runtime's files"
        New-Item -Path $runtimePath -ItemType Directory | Out-Null
        $vcList = [pscustomobject]@{Release = '2012'; Architecture = 'x86'; Path = (Join-Path -Path $runtimePath -ChildPath vcredist_x86.exe)}
        & (Get-Module PhpManager) {
            param ($supportsPath)
            $pathParameter = if ($supportsPath) { ', [Parameter(Mandatory = $true)] [string] $Path' } else { '' }
            Set-Item -LiteralPath Function:script:Install-VcRedist -Value ([scriptblock]::Create(@"
[CmdletBinding()]
param ([Parameter(ValueFromPipeline = `$true)] `$VcList$pathParameter)
process { return `$PSBoundParameters }
"@))
        } $supportsPath
        Mock -ModuleName PhpManager Start-Process {
            $FilePath | Should -BeExactly 'powershell.exe'
            $Verb | Should -BeExactly 'RunAs'
            $Wait | Should -BeExactly $true
            $ArgumentList[0] | Should -Match '^-Command ".*"$'
            $command = $ArgumentList[0].Substring(10, $ArgumentList[0].Length - 11)
            & (Get-Module PhpManager) ([scriptblock]::Create($command))
        }
        try {
            # Run the actual non-administrator block without mocking WindowsIdentity or requesting elevation.
            $startProcess = (Get-Command Install-PhpFromUrl).ScriptBlock.Ast.Find({
                param ($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Start-Process'
            }, $true)
            $block = $startProcess.Parent.Parent
            $block | Should -Be $block.Parent.ElseClause
            $script = [scriptblock]::Create(($block.Statements.Extent.Text -join "`n"))
            # The parent and child deliberately expose opposite parameter shapes.
            $parentParameters = @{}
            if (-Not($supportsPath)) {
                $parentParameters.Path = $runtimePath
            }
            $result = & (Get-Module PhpManager) {
                param ($script, $temporaryDirectory2, $vcList, $vcRedistParameters)
                & $script
            } $script $runtimePath $vcList $parentParameters
            Assert-MockCalled -ModuleName PhpManager Start-Process -Scope It -Times 1 -Exactly
            @($result).Count | Should -Be 1
            $result.ContainsKey('Path') | Should -BeExactly $supportsPath
            if ($supportsPath) {
                $result.Path | Should -BeExactly $runtimePath
            }
            $result.VcList.Path | Should -BeExactly $vcList.Path
            $result.VcList.Release | Should -BeExactly $vcList.Release
            $result.VcList.Architecture | Should -BeExactly $vcList.Architecture
            $result.VcList.PSObject.TypeNames | Should -Contain 'Deserialized.System.Management.Automation.PSCustomObject'
            (Join-Path -Path $runtimePath -ChildPath vcredist.xml) | Should -Exist
        } finally {
            & (Get-Module PhpManager) { Remove-Item -LiteralPath Function:Install-VcRedist }
            Remove-Item -LiteralPath $runtimePath -Recurse -Force
        }
    }
}
