$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
#if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
#}

InModuleScope "$ModuleName" {
    Describe 'Get-FolderSize' {
        $TestDriverSource = Get-Item -Path "$root\tests\Drivers\3T8M8"

        It 'Fails on missing data' {
            {Get-FolderSize -Path $null} | Should Throw
            {Get-FolderSize -Path ''} | Should Throw
        }

        It 'Returns size for specified folder' {
            $FolderSize = Get-FolderSize -Path $TestDriverSource.FullName

            $FolderSize.Dirs | Should be 3
            $FolderSize.Files | Should be 7
            $FolderSize.Bytes | Should Be 947483
            $FolderSize.Bytes | Should BeGreaterOrEqual 1KB
            $FolderSize.Bytes | Should BeLessOrEqual 1GB
        }

        It 'Handles pipeline' {
            $FolderSize = $TestDriverSource | Get-FolderSize

            $FolderSize.Dirs | Should be 3
            $FolderSize.Files | Should be 7
            $FolderSize.Bytes | Should Be 947483
        }

    }
}