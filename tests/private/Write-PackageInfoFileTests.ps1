$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'private/Write-PackageInfoFile' {
        $DriverA = [PSCustomObject]@{
            DriverFile = "TestDrive:\Test.inf"
            Version = "1.0.0.0"
            Class = "TestClass"
            HardwareIDs = [PSCustomObject]@{
                HardwareID = "PCI\TestID"
                HardwareDescription = "Test hardware"
                Architecture = "x86"
            }
        }

        It 'Throw exception if no Driver supplied.' {
            {Write-PackageInfoFile -Driver $null -Path "TestDrive:\InfoTest.json"} | Should throw
        }

        It 'Throw exception if no Path supplied.' {
            {Write-PackageInfoFile -Driver $DriverA -Path $null} | Should throw
            {Write-PackageInfoFile -Driver $DriverA -Path ""} | Should throw
        }

        It 'Throw exception if Path is not a json file.' {
            {Write-PackageInfoFile -Driver $DriverA -Path "TestDrive:\InfoTest.xml"} | Should throw
        }

        It 'Write proper Json to path' {
            Write-PackageInfoFile -Drivers $DriverA -Path "TestDrive:\InfoTest.json"
            $TestFile = Get-Content "TestDrive:\InfoTest.json" | ConvertFrom-Json

            [string]::Compare(($TestFile | ConvertTo-Json), ($DriverA | ConvertTo-Json)) | Should be 0
        }

        It 'File can be read by Read-PackageInfoFile' {
            Write-PackageInfoFile -Drivers $DriverA -Path "TestDrive:\InfoTest.json"
            $TestJson = Read-PackageInfoFile -Path "TestDrive:\InfoTest.json" | ConvertTo-Json

            [string]::Compare($TestJson, ($DriverA | ConvertTo-Json)) | Should be 0
        }

    }
}