$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Compress-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\TestDriver_1.16.51.1"

        It 'Fails on missing data' {
            {Compress-OSDriverPackage -Path ''} | Should Throw
            {Compress-OSDriverPackage -Path $null} | Should Throw
            {Compress-OSDriverPackage -DriverPackage $null} | Should Throw
        }

        BeforeEach {
            $null = Copy-Item -Path $TestDriverSource.FullName -Destination "TestDrive:\" -Force -Recurse
        }

        It 'Compresses a Driver Package' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive
            $DriverPackage.DriverArchiveFile | Should BeLike "*\TestDriver_1.16.51.1.zip"
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false

            Compress-OSDriverPackage -DriverPackage $DriverPackage
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True

            Remove-Item -Path $DriverPackage.DriverArchiveFile -Force
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false

            Compress-OSDriverPackage -DriverPackage $DriverPackage -ArchiveType CAB
            $DriverPackage.DriverArchiveFile | Should BeLike "*\TestDriver_1.16.51.1.cab"
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True
        }

        It 'Compresses a Driver Package by path' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive
            $DriverPackage = Compress-OSDriverPackage -Path ($DriverPackage.DefinitionFile) -Passthru
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True
            $DriverPackage.DriverArchiveFile | Should BeLike "*\TestDriver_1.16.51.1.zip"
        }

        AfterEach {
            Get-ChildItem -Path $TestDrive | Remove-Item -Recurse -Force
        }
    }
}