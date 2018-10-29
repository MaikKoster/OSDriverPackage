$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Test-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\3T8M8"
        $TestDriverPackage = [PSCustomObject]@{
            DriverPackage = "$TestDrive\3T8M8"
            DefinitionFile = "$TestDrive\3T8M8.def"
            Definition = $null
            DriverInfoFile = "$TestDrive\3T8M8.json"
            DriverArchiveFile = "$TestDrive\3T8M8.zip"
            DriverPath = "$TestDrive\3T8M8"
            Drivers = $null
        }

        BeforeEach {
            $null = Copy-Item -Path $TestDriverSource.FullName -Destination "TestDrive:\" -Force -Recurse
        }

        It 'Fails on missing data' {
            {Test-OSDriverPackage -DriverPackage $null} | Should Throw
            {Test-OSDriverPackage -DriverPackage $TestDriverPackage} | Should Throw
        }

        It 'Returns false on missing driver definition' {
            Set-Content -Path ($TestDriverPackage.DefinitionFile) -Value 'JustSomeTestContent'
            Test-OSDriverPackage -DriverPackage $TestDriverPackage | Should Be $false
        }

        It 'Returns false on missing driver content' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true

            # Remove Drivers
            Remove-Item -Path ($DriverPackage.DriverPath) -Force -Recurse
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $false
        }

        It 'Returns false on missing driver content' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true

            # Remove Drivers
            Remove-Item -Path ($DriverPackage.DriverArchiveFile) -Force -Recurse
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $false
        }

        It 'Sets default path for driver content' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $OldDriverPath = $DriverPackage.DriverPath
            $OldDriverArchiveFile = $DriverPackage.DriverArchiveFile
            $DriverPackage.DriverPath = ''
            $DriverPackage.DriverArchiveFile = ''
            $Result = Test-OSDriverPackage -DriverPackage $DriverPackage

            $Result | Should Be $true
            $DriverPackage.DriverPath | Should Be $OldDriverPath
            $DriverPackage.DriverArchiveFile | Should Be $OldDriverArchiveFile
        }

        It 'Handles pipeline' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $DriverPackage | Test-OSDriverPackage | Should Be $true
        }

        It 'Loads drivers if missing' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $DriverPackage.Drivers = $null
            $DriverPackage.Drivers.Count | Should Be 0

            $Result = Test-OSDriverPackage -DriverPackage $DriverPackage
            $Result | Should Be $true
            $DriverPackage.Drivers.Count | Should Be 2
        }

        It 'Returns false on 0 drivers' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true

            Mock Get-OSDriver {$null}

            # Remove Drivers
            $DriverPackage.Drivers = $null
            Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $false
        }

        AfterEach {
            Remove-Item -Path 'TestDrive:\*.*' -Recurse -Force
        }
    }
}