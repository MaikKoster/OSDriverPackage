$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Clean-OSDriverPackage' {

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
            {Clean-OSDriverPackage -DriverPackage $null} | Should Throw
        }

        It 'Removes unreferenced files from Driver Package' {
            Test-Path -Path "$($DriverHighVersion.DriverPath)\Driver_Win10\CleanMe.txt" | Should Be $true

            $Result = $DriverHighVersion | Clean-OSDriverPackage -RemoveUnreferencedFiles

            Test-Path -Path "$($DriverHighVersion.DriverPath)\Driver_Win10\CleanMe.txt" | Should Be $false
            $Result | Should Not Be $null
            $Result.OldDriverCount | Should Be $Result.NewDriverCount
        }

        It 'Loads drivers if they are missing' {
            $DriverHighVersion.Drivers = $null

            Clean-OSDriverPackage -DriverPackage $DriverHighVersion -RemoveUnreferencedFiles
            $DriverHighVersion.Drivers | Should Not Be $null
        }

        It 'Identifies and removes drivers that can be removed' {
            $Result = Clean-OSDriverPackage -CoreDriverPackage $DriverMediumVersion -DriverPackage $DriverLowVersion

            $Result.OldDriverCount | Should BeGreaterThan $Result.NewDriverCount
            $Result.NewDriverCount | Should Be $DriverLowVersion.Drivers.Count
        }

        It 'Deletes a driver package, if all drivers can be removed' {
            $null = Copy-Item -Path "$($DriverLowVersion.DriverPath)" -Destination "TestDrive:\Drivers\TestDriver_1.16.32.2" -Force -Recurse

            $DriverLowVersion2 = New-OSDriverPackage -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.2') -KeepFiles

            $Result = Clean-OSDriverPackage -CoreDriverPackage $DriverLowVersion -DriverPackage $DriverLowVersion2

            $Result.OldDriverCount | Should BeGreaterThan $Result.NewDriverCount
            $Result.NewDriverCount | Should Be 0
            $DriverLowVersion2.DefinitionFile | Should Be ''
            $DriverLowVersion2.DriverPath | Should Be ''
            $DriverLowVersion2.DriverArchiveFile | Should Be ''
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.2') | Should Be $false
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.2.zip') | Should Be $false
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.2.def') | Should Be $false
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath 'Drivers\TestDriver_1.16.32.2.info') | Should Be $false
        }

    }
}