$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = $here -replace "\\public|\\private|\\tests", ""
$ModuleName = 'OSDriverPackage'

# Import our module to use InModuleScope
if (-Not(Get-Module -Name "$ModuleName")) {
    Import-Module (Resolve-Path "$root\$ModuleName\$ModuleName.psd1") -Force
}

InModuleScope "$ModuleName" {
    Describe 'private/Compare-OSDriver' {
        $DriverA = [PSCustomObject]@{
            DriverFile = 'C:\temp\DriverA.inf'
            DriverInfo = @([PSCustomObject]@{
                Version = '1.1.0.1'
                HardwareID = 'PCI\VEN_1234&DEV_5678'
                },[PSCustomObject]@{
                    Version = '1.1.0.1'
                    HardwareID = 'PCI\VEN_1234&DEV_6789'
                })
            DriverSourceFiles = ''
        }
        $DriverB = [PSCustomObject]@{
            DriverFile = 'C:\temp\DriverB.inf'
            DriverInfo = [PSCustomObject]@{
                Version = '1.1.0.0'
                HardwareID = 'PCI\VEN_1234&DEV_5678'
            }
            DriverSourceFiles = ''
        }
        $DriverC = [PSCustomObject]@{
            DriverFile = 'C:\temp\DriverC.inf'
            DriverInfo = [PSCustomObject]@{
                Version = '1.2.0.1'
                HardwareID = 'PCI\VEN_1234&DEV_5678'
            }
            DriverSourceFiles = ''
        }
        $DriverD = [PSCustomObject]@{
            DriverFile = 'C:\temp\DriverD.inf'
            DriverInfo = [PSCustomObject]@{
                Version = '1.1.0.0'
                HardwareID = 'PCI\VEN_1234&DEV_3456'
            }
            DriverSourceFiles = ''
        }

        It 'Throw exception if no Core Driver supplied.' {
            {Compare-OSDriver -CoreDriver $null -PackageDriver $DriverA} | Should throw
        }

        It 'Throw exception if no Package Driver supplied.' {
            {Compare-OSDriver -CoreDriver $DriverA -PackageDriver $null} | Should throw
        }

        Context 'No pipeline' {
            It 'Return True if Core Package has the same version' {
                Compare-OSDriver -CoreDriver $DriverA -PackageDriver $DriverA | Should Be $true
            }

            It 'Return True if Core Package has the higher version' {
                Compare-OSDriver -CoreDriver $DriverA -PackageDriver $DriverB | Should Be $true
            }

            It 'Return False if Core Package has the lower version' {
                Compare-OSDriver -CoreDriver $DriverA -PackageDriver $DriverC | Should Be $false
            }

            It 'Return False if not all PnP IDs are covered by Core Package' {
                Compare-OSDriver -CoreDriver $DriverA -PackageDriver $DriverD | Should Be $false
            }
        }

        Context 'using pipeline' {
            It 'Return True if Core Package has the same version' {
                $DriverA | Compare-OSDriver -CoreDriver $DriverA | Should Be $true
            }

            It 'Return True if Core Package has the higher version' {
                $DriverB | Compare-OSDriver -CoreDriver $DriverA | Should Be $true
            }

            It 'Return False if Core Package has the lower version' {
                $DriverC | Compare-OSDriver -CoreDriver $DriverA | Should Be $false
            }

            It 'Return False if not all PnP IDs are covered by Core Package' {
                $DriverD | Compare-OSDriver -CoreDriver $DriverA | Should Be $false
            }

            It 'Add Replace property if PassThru is set' {
                $DriverB | Compare-OSDriver -CoreDriver $DriverA -PassThru | Select-Object -ExpandProperty Replace | Should Be $true
                $DriverD | Compare-OSDriver -CoreDriver $DriverA -PassThru | Select-Object -ExpandProperty Replace | Should Be $false
            }

            It 'Update Replace property if PassThru is set' {
                $DriverB = $DriverB | Compare-OSDriver -CoreDriver $DriverA -PassThru
                $DriverB.Replace = $false
                $DriverB | Compare-OSDriver -CoreDriver $DriverA -PassThru | Select-Object -ExpandProperty Replace | Should Be $true
            }
        }

    }
}