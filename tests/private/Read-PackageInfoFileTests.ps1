$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'private/Read-PackageInfoFile' {
        $DriverA = [PSCustomObject]@{
            DriverFile = "TestDrive:\Test.inf"
            DriverVersion = "1.0.0.0"
            DriverClass = "TestClass"
            HardwareIDs = [PSCustomObject]@{
                HardwareID = "PCI\TestID"
                HardwareDescription = "Test hardware"
                Architecture = "x86"
            }
        }

        It 'Throw exception if no Path supplied.' {
            {Read-PackageInfoFile -Path $null} | Should throw
            {Read-PackageInfoFile -Path ""} | Should throw
        }

        It 'Throw exception if Path is not a json file.' {
            {Read-PackageInfoFile -Path "TestDrive:\InfoTest.xml"} | Should throw
        }

        It 'Read proper object from path' {
            $TestJson = $DriverA | ConvertTo-Json
            $TestJson | Set-Content -Path "TestDrive:\InfoTest.json"
            $TestFile = Read-PackageInfoFile -Path "TestDrive:\InfoTest.json"

            [string]::Compare($TestJson, ($TestFile | ConvertTo-Json)) | Should be 0
        }

        It 'File from Write-PackageInfoFile can be read' {
            Write-PackageInfoFile -Drivers $DriverA -Path "TestDrive:\InfoTest.json"
            $TestJson = Read-PackageInfoFile -Path "TestDrive:\InfoTest.json" | ConvertTo-Json

            [string]::Compare($TestJson, ($DriverA | ConvertTo-Json)) | Should be 0
        }
    }
}