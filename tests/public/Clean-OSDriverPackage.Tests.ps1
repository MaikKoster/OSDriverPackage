$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Clean-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\TestDriver_1.16.51.1"

        It 'Fails on missing data' {
            {Clean-OSDriverPackage -DriverPackage $null} | Should Throw
        }

        BeforeEach {
            $null = Copy-Item -Path $TestDriverSource.FullName -Destination "TestDrive:\" -Force -Recurse
        }

        It 'Removes unreferenced files from Driver Package' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive -KeepFiles

            Test-Path -Path "$TestDrive\TestDriver_1.16.51.1\Driver_Win10\CleanMe.txt" | Should Be $true

            $Result = $DriverPackage | Clean-OSDriverPackage -RemoveUnreferencedFiles -NoArchive

            Test-Path -Path "$TestDrive\TestDriver_1.16.51.1\Driver_Win10\CleanMe.txt" | Should Be $false
            $Result | SHould Not Be $null
            $Result.OldDriverCount | Should Be $Result.NewDriverCount
        }

        AfterEach {
            Get-ChildItem -Path $TestDrive | Remove-Item -Recurse -Force
        }
    }
}