Describe 'Syntax' {

    $testCases = Get-ChildItem -Path $Global:PHPMANAGER_FOLDER -Include *.ps1, *.psm1 -Recurse | ForEach-Object {@{file = $_}}

    It -Name '<file> should be a valid PowerShell script' -TestCases $testCases {
        param($file)
        $file.FullName | Should Exist
        $contents = Get-Content -Path $file.FullName -ErrorAction Stop
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors) | Out-Null
        $errors.Count | Should Be 0
    }

    It -Name '<file> should pass PSScriptAnalyzer' -TestCases $testCases {
        param($file)
        $problems = @(Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule PSUseShouldProcessForStateChangingFunctions -Severity Warning, Error)
        If ($problems) {
            $problems | Format-Table | Out-String | Write-Host
        }
        @($problems).Count | Should Be 0
    }
}
