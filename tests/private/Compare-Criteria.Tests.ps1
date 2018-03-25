$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'Compare-Criteria' {
        $Section = [ordered]@{
            OSVersion = 'Win10'
            Architecture = ''
            Model = 'ModelA, ModelB'
            Make = ''
            ExcludeMake = 'MakeA'
        }

        It 'Throw exception if no section or include name supplied.' {
            {Compare-Criteria -Section $null -Include 'Test'} | Should throw
            {Compare-Criteria -Section $Section -Include ''} | Should throw
        }

        It 'Match on empty criteria' {
            Compare-Criteria -Section $Section -Filter '' -Include 'Architecture' | Should Be $true
            Compare-Criteria -Section $Section -Filter 'x64' -Include 'Architecture' | Should Be $true
            Compare-Criteria -Section $Section -Filter '' -Include 'OSVersion' | Should Be $true
            Compare-Criteria -Section $Section -Include 'OSVersion' | Should Be $true
        }

        It 'Match on include' {
            Compare-Criteria -Section $Section -Filter 'Win10' -Include 'OSVersion' | Should Be $true
            Compare-Criteria -Section $Section -Filter 'Win7' -Include 'OSVersion' | Should Be $false
        }

        It 'No match on exclude' {
            Compare-Criteria -Section $Section -Filter 'MakeA' -Include 'Make' | Should Be $false
            Compare-Criteria -Section $Section -Filter 'MakeB' -Include 'Make' | Should Be $true
        }

    }
}