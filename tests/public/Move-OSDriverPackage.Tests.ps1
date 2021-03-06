$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Move-OSDriverPackage' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\TestDriver_1.16.51.1"
        $TargetPath = Join-Path -Path $TestDrive -ChildPath 'MoveTarget'

        It 'Fails on missing data' {
            {Move-OSDriverPackage -Path ''} | Should Throw
            {Move-OSDriverPackage -Path $null} | Should Throw
            {Move-OSDriverPackage -DriverPackage $null} | Should Throw
        }

        BeforeEach {
            $null = Copy-Item -Path $TestDriverSource.FullName -Destination "TestDrive:\" -Force -Recurse
            New-Item -Path $TargetPath -ItemType Directory -Force
        }

        It 'Moves a Driver Package' {
            $OldDriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -NoArchive

            $NewDriverPackage = Move-OSDriverPackage -DriverPackage $OldDriverPackage -Destination $TargetPath -PassThru

            $NewDriverPackage.DefinitionFile | Should BeLike "$TargetPath*.def"
            Test-Path -Path $NewDriverPackage.DefinitionFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DefinitionFile | Should Be $false

            $NewDriverPackage.DriverArchiveFile | Should BeLike "$TargetPath*.zip"
            Test-Path -Path $NewDriverPackage.DriverArchiveFile | Should Be $false
            Test-Path -Path $OldDriverPackage.DriverArchiveFile | Should Be $false

            $NewDriverPackage.DriverInfoFile | Should BeLike "$TargetPath*.json"
            Test-Path -Path $NewDriverPackage.DriverInfoFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DriverInfoFile | Should Be $false

            $NewDriverPackage.DriverPath | Should BeLike "$TargetPath*"
            Test-Path -Path $NewDriverPackage.DriverPath | Should Be $true
            Test-Path -Path $OldDriverPackage.DriverPath | Should Be $false
        }

        It 'Moves OSD related files only' {
            $OldDriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)" -KeepFiles

            $NewDriverPackage = Move-OSDriverPackage -DriverPackage $OldDriverPackage -Destination $TargetPath -PassThru -OSD

            $NewDriverPackage.DefinitionFile | Should BeLike "$TargetPath*.def"
            Test-Path -Path $NewDriverPackage.DefinitionFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DefinitionFile | Should Be $false

            $NewDriverPackage.DriverArchiveFile | Should BeLike "$TargetPath*.zip"
            Test-Path -Path $NewDriverPackage.DriverArchiveFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DriverArchiveFile | Should Be $false

            $NewDriverPackage.DriverInfoFile | Should BeLike "$TargetPath*.json"
            Test-Path -Path $NewDriverPackage.DriverInfoFile | Should Be $false
            Test-Path -Path $OldDriverPackage.DriverInfoFile | Should Be $true

            $NewDriverPackage.DriverPath | Should BeLike "$TargetPath*"
            Test-Path -Path $NewDriverPackage.DriverPath | Should Be $false
            Test-Path -Path $OldDriverPackage.DriverPath | Should Be $true
        }

        It 'Does not overwrite existing files on default' {
            $OldDriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $TestInfoFilePath = Join-Path -Path $TargetPath -ChildPath (Split-Path -Path $OldDriverPackage.DriverInfoFile -Leaf)
            'Just some test content' | Set-Content -Path $TestInfoFilePath -Force
            $OldSize = (Get-Item -Path $TestInfoFilePath).Length

            $NewDriverPackage = Move-OSDriverPackage -DriverPackage $OldDriverPackage -Destination $TargetPath -PassThru -ErrorAction SilentlyContinue
            $NewSize = (Get-Item -Path $TestInfoFilePath).Length

            $OldSize | Should Be $NewSize
            $NewDriverPackage.DriverInfoFile | Should BeLike "$TargetPath*.json"
            Test-Path -Path $NewDriverPackage.DriverInfoFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DriverInfoFile | Should Be $true
        }

        It 'Overwrites files if specified' {
            $OldDriverPackage = New-OSDriverPackage -Path "$TestDrive\$($TestDriverSource.BaseName)"
            $TestInfoFilePath = Join-Path -Path $TargetPath -ChildPath (Split-Path -Path $OldDriverPackage.DriverInfoFile -Leaf)
            'Just some test content' | Set-Content -Path $TestInfoFilePath -Force
            $OldSize = (Get-Item -Path $TestInfoFilePath).Length

            $NewDriverPackage = Move-OSDriverPackage -DriverPackage $OldDriverPackage -Destination $TargetPath -PassThru -Force
            $NewSize = (Get-Item -Path $TestInfoFilePath).Length

            $OldSize | Should Not Be $NewSize
            $NewDriverPackage.DriverInfoFile | Should BeLike "$TargetPath*.json"
            Test-Path -Path $NewDriverPackage.DriverInfoFile | Should Be $true
            Test-Path -Path $OldDriverPackage.DriverInfoFile | Should Be $false
        }

        AfterEach {
            Get-ChildItem -Path $TestDrive | Remove-Item -Recurse -Force
        }
    }
}