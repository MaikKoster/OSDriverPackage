$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {

    Describe 'Compare-OSDriverPackage' {

        BeforeAll {
            $DriverSourcePath = Join-Path -Path $root -ChildPath 'tests\Drivers'
            $null = Copy-Item -Path $DriverSourcePath -Destination "TestDrive:\" -Force -Recurse

            $null = New-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.1') -KeepFiles
            $null = New-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.49.1') -KeepFiles
            $null = New-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.51.1') -KeepFiles
        }

        BeforeEach {
            $DriverLowVersion = Get-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.1') -ReadDrivers
            $DriverMediumVersion = Get-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.49.1') -ReadDrivers
            $DriverHighVersion = Get-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.51.1') -ReadDrivers
        }

        It 'Fails on missing data' {
            {Compare-OSDriverPackage -CoreDriverPackage $null -DriverPackage $DriverLowVersion} | Should Throw
            {Compare-OSDriverPackage -CoreDriverPackage $DriverLowVersion -DriverPackage $null} | Should Throw
            {Compare-OSDriverPackage -CoreDriverPackage $null -DriverPackage $null} | Should Throw
        }

        It 'Loads drivers if they are missing' {
            $DriverLowVersion.Drivers = $null
            $DriverMediumVersion.Drivers = $null

            Compare-OSDriverPackage -CoreDriverPackage $DriverMediumVersion -DriverPackage $DriverLowVersion
            $DriverLowVersion.Drivers | Should Not Be $null
            $DriverMediumVersion.Drivers | Should Not Be $null
        }

        It 'Identifies drivers that can be removed' {
            Compare-OSDriverPackage -CoreDriverPackage $DriverMediumVersion -DriverPackage $DriverLowVersion

            $DriverLowVersion.Drivers | Where-Object {$_.LowerVersion} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 2
            $DriverLowVersion.Drivers | Where-Object {$_.Replace} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
            $DriverLowVersion.Drivers | Where-Object {$_.Replace} | Select-Object -ExpandProperty MissingHardwareIDs | Should Be $null
            $DriverLowVersion.Drivers | Where-Object {-Not($_.Replace)} | Select-Object -ExpandProperty MissingHardwareIDs | Should Not Be $null
        }

        It 'Properly handles different architectures' {
            Compare-OSDriverPackage -CoreDriverPackage $DriverHighVersion -DriverPackage $DriverMediumVersion

            $DriverMediumVersion.Drivers | Where-Object {$_.LowerVersion} | Measure-Object | Select-Object -ExpandProperty Count | Should Be 1
            $DriverMediumVersion.Drivers | Where-Object {$_.Replace} | Should Be $null
            $DriverMediumVersion.Drivers.MissingHardwareIDs | Where-Object {$_.Architecture -eq 'x64'} | Should Be $Null
            $DriverMediumVersion.Drivers.MissingHardwareIDs | Where-Object {$_.Architecture -eq 'x86'} | Should Not Be $Null
        }

    }
}