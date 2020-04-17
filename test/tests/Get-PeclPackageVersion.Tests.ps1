Describe 'Get-PeclPackageVersion' {

    Context 'Context #1' {

        Mock -ModuleName PhpManager Invoke-RestMethod { return [xml]@'
<?xml version="1.0" encoding="UTF-8" ?>
<a xmlns="http://pear.php.net/dtd/rest.allreleases">
    <p>samplepackage</p>
    <c>pecl.php.net</c>
    <r><v>3.0.0</v><s>stable</s></r>
    <r><v>2.7.0beta1</v><s>beta</s></r>
    <r><v>2.6.0</v><s>stable</s></r>
    <r><v>2.6.0beta1</v><s>beta</s></r>
    <r><v>2.6.0alpha2</v><s>alpha</s></r>
    <r><v>2.6.0alpha1</v><s>alpha</s></r>
    <r><v>2.5.5</v><s>stable</s></r>
    <r><v>2.0.0</v><s>stable</s></r>
    <r><v>1.9.9</v><s>stable</s></r>
</a>
'@ } -ParameterFilter { $Method -eq 'Get' -and $Uri -clike '*/samplepackage/allreleases.xml' }

        $minimumStabilities = @('_DEFAULT_', 'stable', 'beta', 'alpha', 'devel', 'snapshot') | ForEach-Object { @{minimumStability = $_} }
        It 'should detect the correct version considering the <minimumStability> minimum stability' -TestCases $minimumStabilities {
            param ($minimumStability)
            if ($minimumStability -eq '_DEFAULT_') {
                $versions = Get-PeclPackageVersion -Handle 'SamplePackage' -Version '2'
            } else {
                $versions = Get-PeclPackageVersion -Handle 'SamplePackage' -Version '2' -Stability $minimumStability
            }
            Assert-MockCalled -ModuleName PhpManager Invoke-RestMethod -Scope It -Times 1 -Exactly
            $versionsJoined = $versions -join '___'
            switch -regex ($minimumStability) {
                '_DEFAULT_|stable' {
                    $versions -join ' ' | Should -BeExactly '2.6.0 2.5.5 2.0.0'
                }
                'beta' {
                    $versions -join ' ' | Should -BeExactly '2.7.0beta1 2.6.0 2.6.0beta1 2.5.5 2.0.0'
                }
                'alpha|devel|snapshot' {
                    $versions -join ' ' | Should -BeExactly '2.7.0beta1 2.6.0 2.6.0beta1 2.6.0alpha2 2.6.0alpha1 2.5.5 2.0.0'
                }
            }
        }
    }
}
