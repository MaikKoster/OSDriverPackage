$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Expand-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\TestDriver_1.16.51.1"

        It 'Fails on missing data' {
            {Expand-OSDriverPackage -Path ''} | Should Throw
            {Expand-OSDriverPackage -Path $null} | Should Throw
            {Expand-OSDriverPackage -DriverPackage $null} | Should Throw
        }

        BeforeEach {
            $null = Copy-Item -Path $TestDriverSource.FullName -Destination "TestDrive:\" -Force -Recurse
        }

        It 'Expands a Driver Package' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $DriverPackage.DriverPath | Should BeLike "*\TestDriver_1.16.51.1"
            Test-Path -Path $DriverPackage.DriverPath | Should Be $false
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $true

            Expand-OSDriverPackage -DriverPackage $DriverPackage
            Test-Path -Path $DriverPackage.DriverPath | Should Be $True
        }

        It 'Expands a Driver Package by path and remove archive' {
            $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $DriverPackage = Expand-OSDriverPackage -Path ($DriverPackage.DefinitionFile) -Passthru -RemoveArchive
            Test-Path -Path $DriverPackage.DriverPath | Should Be $true
            Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false
            $DriverPackage.DriverPath | Should BeLike "*\TestDriver_1.16.51.1"
        }

        It 'Expands a zip file without a Driver Package' {
            $SourcePath = "$TestDrive\$($TestDriverSource.BaseName)"
            $ArchivePath = "$SourcePath.zip"
            Compress-Archive -Path $SourcePath -DestinationPath $ArchivePath
            Remove-Item -Path $SourcePath -Force -Recurse
            Expand-OSDriverPackage -Path $ArchivePath -ExpandOnly

            Test-Path -Path $SourcePath | Should Be $True
        }

        # It 'Creates new Driver Package with cab archive' {
        #     $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -ArchiveType 'cab'

        #     $DriverPackage | Should Not Be $null
        #     Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $false
        #     $DriverPackage.DriverArchiveFile | Should BeLike "*\TestDriver_1.16.51.1.cab"
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\TestDriver_1.16.51.1"
        # }


        # It 'Creates new Driver Package without archive' {
        #     $DriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive

        #     $DriverPackage | Should Not Be $null
        #     Test-OSDriverPackage -DriverPackage $DriverPackage | Should Be $true
        #     Test-Path -Path $DriverPackage.DefinitionFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverInfoFile | Should Be $true
        #     Test-Path -Path $DriverPackage.DriverArchiveFile | Should Be $false
        #     Test-Path -Path $DriverPackage.DriverPath | Should Be $true
        #     $DriverPackage.DriverArchiveFile | Should BeLike "*\TestDriver_1.16.51.1.zip"
        #     $DriverPackage.Drivers.Count | Should Be 2
        #     $DriverPackage.Definition | Should Not Be $null
        #     $DriverPackage.Definition.Count | Should Be 2
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\TestDriver_1.16.51.1"
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
        #     $DriverPackage.DriverPath | Should Be "$TestDrive\TestDriver_1.16.51.1"
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
            Get-ChildItem -Path $TestDrive | Remove-Item -Recurse -Force
        }
    }
}