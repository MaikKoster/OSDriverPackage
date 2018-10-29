$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Compress-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\3T8M8"

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
            $DriverPackage.DriverArchiveFile | Should BeLike "*\3T8M8.zip"
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false

            Compress-OSDriverPackage -DriverPackage $DriverPackage
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True

            Remove-Item -Path $DriverPackage.DriverArchiveFile -Force
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false

            Compress-OSDriverPackage -DriverPackage $DriverPackage -ArchiveType CAB
            $DriverPackage.DriverArchiveFile | Should BeLike "*\3T8M8.cab"
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True
        }

        It 'Compresses a Driver Package by path' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive
            $DriverPackage = Compress-OSDriverPackage -Path ($DriverPackage.DefinitionFile) -Passthru
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $True
            $DriverPackage.DriverArchiveFile | Should BeLike "*\3T8M8.zip"
        }

        # It 'Creates new Driver Package with cab archive' {
        #     $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -ArchiveType 'cab'

        #     $DriverPackage | Should Not Be $null
        #     Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $false
        #     $DriverPackage.DriverArchiveFile | Should BeLike "*\3T8M8.cab"
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\3T8M8"
        # }


        # It 'Creates new Driver Package without archive' {
        #     $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive

        #     $DriverPackage | Should Not Be $null
        #     Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $true
        #     $DriverPackage.DriverArchiveFile | Should BeLike "*\3T8M8.zip"
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\3T8M8"
        # }

        # It 'Create new Driver Package and keep original files' {
        #     $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -KeepFiles

        #     $DriverPackage | Should Not Be $null
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $true
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\3T8M8"
        #     Test-Path -Path (Join-Path -Path $DriverPackage.DriverPath -ChildPath 'Driver_Win10\CleanMe.txt') | Should Be $true
        # }

        # It 'Create new Driver Package and cleanup files' {
        #     Copy-Item -Path $TestDriver.FullName -Destination "TestDrive:\" -Force -PassThru -Recurse

        #     $DriverPackage = New-OSDriverPackage -Path "TestDrive:\$($TestDriver.BaseName)" -Clean -KeepFiles

        #     $DriverPackage | Should Not Be $null
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $true
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Not Be ''
        #     Test-Path -Path (Join-Path -Path $TestDriver.FullName -ChildPath 'Driver_Win10\CleanMe.def') | Should Be $false
        # }

        AfterEach {
            Remove-Item -Path TestDrive:\*.* -Recurse -Force
        }
    }
}