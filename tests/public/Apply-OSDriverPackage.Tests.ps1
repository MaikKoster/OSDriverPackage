$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'Apply-OSDriverPackage' {
        # Mock everything first
        Mock Get-CimInstance {
            [PSCustomObject]@{
                Manufacturer = 'MakeA'
                Model = 'ModelA'
            }
        } -ParameterFilter {$ClassName -eq 'Win32_ComputerSystem'}

        Mock Get-PNPDevice {@('PCI\Testdevice1','PCI\Testdevice2')}
        Mock Get-OSDriverPackage {}
        Mock Get-OSDriverPackage {
            [PSCustomObject]@{
                DriverPackage = "$TestDrive\TestA.zip"
            }
        } -ParameterFilter {$Tag -eq 'GetPackage'}
        Mock Expand-Archive {}

        BeforeAll {
            $Source = Join-Path -Path $Testdrive -ChildPath 'Source'
            $Destination = Join-Path -Path $Testdrive -ChildPath 'Destination'
            $null = New-Item -Path $Source -ItemType Directory -Force
        }

        It 'Throw exception if path or destination are missing.' {
            {Apply-OSDriverPackage -Path "$Testdrive" -Destination $null} | Should throw
            {Apply-OSDriverPackage -Path "$Testdrive" -Destination ''} | Should throw
            {Apply-OSDriverPackage -Path '' -Destination "$Testdrive"} | Should throw
            {Apply-OSDriverPackage -Path $null -Destination "$Testdrive"} | Should throw
        }

        It 'Create Destination if path does not exist yet' {
            Test-Path -Path $Destination | Should Be $false
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoMake -NoModel -NoHardwareID -NoWQL
            Test-Path -Path $Destination | Should Be $true
        }

        It 'Get Make and Model' {
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoMake -NoModel
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 0 -ParameterFilter {$Make -eq 'MakeA' -and $Model -eq 'ModelA'} -Scope It

            # Make
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoModel
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 0 -ParameterFilter {$Make -eq 'MakeA' -and $Model -eq 'ModelA'} -Scope It
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$Make -eq 'MakeA'} -Scope It

            # Model
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoMake
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 0 -ParameterFilter {$Make -eq 'MakeA' -and $Model -eq 'ModelA'} -Scope It
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$Model -eq 'ModelA'} -Scope It

            # Make and Model
            Apply-OSDriverPackage -Path $Source -Destination $Destination
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$Make -eq 'MakeA' -and $Model -eq 'ModelA'} -Scope It
        }

        It 'Get Hardware IDs' {
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoHardwareID
            Assert-MockCalled -CommandName Get-PNPDevice -Times 0 -Scope It
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$HardwareIDs -eq $null} -Scope It

            # HardwareID
            Apply-OSDriverPackage -Path $Source -Destination $Destination
            Assert-MockCalled -CommandName Get-PNPDevice -Times 1 -Scope It
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$HardwareIDs.Count -eq 2} -Scope It
        }

        It 'Use WQL' {
            Apply-OSDriverPackage -Path $Source -Destination $Destination -NoWQL
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$UseWQL.IsPresent -eq $false} -Scope It

            # HardwareID
            Apply-OSDriverPackage -Path $Source -Destination $Destination
            Assert-MockCalled -CommandName Get-OSDriverPackage -Times 1 -ParameterFilter {$UseWQL.IsPresent} -Scope It
        }

        It 'Expand Driver Package' {
            Apply-OSDriverPackage -Path $Source -Destination $Destination
            Assert-MockCalled -CommandName Expand-Archive -Times 0 -Scope It

            Apply-OSDriverPackage -Path $Source -Destination $Destination -Tag 'GetPackage'
            Assert-MockCalled -CommandName Expand-Archive -Times 1 -Scope It
        }
    }
}