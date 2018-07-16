$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'New-ExportDefinition' {
        It 'Fail on missing data' {
            {New-ExportDefinition -Name '' -SourceRoot 'TestDrive:\Source' -TargetRoot 'TestDrive:\Target'} | Should Throw
            {New-ExportDefinition -Name 'Test' -SourceRoot '' -TargetRoot 'TestDrive:\Target'} | Should Throw
            {New-ExportDefinition -Name 'Test' -SourceRoot 'TestDrive:\Source' -TargetRoot ''} | Should Throw
        }

        It 'Fail if path does not exist' {
            {New-ExportDefinition -Name 'Test' -SourceRoot 'TestDrive:\Source' -TargetRoot 'TestDrive:\Target'} | Should Throw
        }

        Context 'No previous ExportDefinition file' {
            It 'Create new Export Definition' {
                Test-Path -Path 'TestDrive:\Source\DriverPackageExports.json' | Should be $false
                New-Item -Path 'TestDrive:\' -Name 'Source' -ItemType directory -Force
                $Def = New-ExportDefinition -Name 'TestExport' -SourceRoot 'TestDrive:\Source' -TargetRoot 'TestDrive:\Target'

                $Def | SHould Not Be $Null
                $Def.Name | Should Be 'TestExport'
                Test-Path -Path 'TestDrive:\Source\DriverPackageExports.json' | Should be $true
            }
        }

        Context 'Existing ExportDefinition file' {
            It 'Create new Export Definition' {
                Test-Path -Path 'TestDrive:\Source\DriverPackageExports.json' | Should be $false
                New-Item -Path 'TestDrive:\' -Name 'Source' -ItemType directory -Force
                $null = New-ExportDefinition -Name 'TestExport' -SourceRoot 'TestDrive:\Source' -TargetRoot 'TestDrive:\Target'
                $Def = New-ExportDefinition -Name 'TestExport2' -SourceRoot 'TestDrive:\Source' -TargetRoot 'TestDrive:\Target'

                $Def | SHould Not Be $Null
                $Def.Name | Should Be 'TestExport2'
                Test-Path -Path 'TestDrive:\Source\DriverPackageExports.json' | Should be $true

                $AllDefs = Get-ExportDefinition -Path 'TestDrive:\Source'
                $AllDefs.Count | Should be 2
            }
        }
    }
}