Describe 'Get-PeclAvailablePackage' {

    It 'should return an array of strings' {
        $packages = Get-PeclAvailablePackage
        $packages.Count | Should -BeGreaterThan 0
        $packages | Should -BeOfType string
    }
}
