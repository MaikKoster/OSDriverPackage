$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Get-OSDriverFile' {
        $TestDriver = Get-Item -Path "$root\tests\Drivers\3T8M8"

        It 'Fail on missing data' {
            {Get-OSDriverFile -Path ''} | Should Throw
            {Get-OSDriverFile -Path $null} | Should Throw
            {Get-OSDriverFile -DriverPackage $null} | Should Throw
        }

        It 'Get Driver files from path' {
            Copy-Item -Path $TestDriver.FullName -Destination "TestDrive:\" -Force -PassThru -Recurse

            $Drivers = Get-OSDriverFile -Path "TestDrive:\$($TestDriver.BaseName)"

            $Drivers.Count | Should Be 2
        }

        It 'Get Driver files from archive' {
            Copy-Item -Path $TestDriver.FullName -Destination "TestDrive:\" -Force -PassThru -Recurse
            $Archive = Compress-Folder -Path (Join-Path -Path $TestDrive -ChildPath $TestDriver.BaseName) -RemoveSource
            $Drivers = Get-OSDriverFile -Path $Archive

            $Drivers.Count | Should Be 2
        }

        It 'Get Driver files from DriverPackage' {
            Copy-Item -Path $TestDriver.FullName -Destination "TestDrive:\" -Force -PassThru -Recurse

            $Drivers = Get-OSDriverFile -Path "TestDrive:\$($TestDriver.BaseName)"

            $Drivers.Count | Should Be 2
        }

    }
}