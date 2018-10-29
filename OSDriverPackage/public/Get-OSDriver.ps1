function Get-OSDriver {
    <#
    .SYNOPSIS
        Returns information about the specified driver.

    .DESCRIPTION
        Returns information about the specified driver and the related files.

    #>
    [CmdletBinding()]
    [OutputType([array])]
    param (
        # Specifies the name and path for the driver file
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -match '\.(inf|json)') -and (-Not((Get-Item $_).PSIsContainer))})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Get driver ('Path':'$Path')")

        $Driver = Get-Item $Path
        if ($Driver.Name -eq 'autorun.inf') {
            $script:Logger.Warn("Skipping '$Path'.")
        } elseif ($Driver.Extension -eq '.inf') {
            $script:Logger.Info("Get windows driver info from '$Path'")

            # Preference on custom Get-OSDriverInf function.
            # Fall back to Get-WindowsDriver if something fails.
            try {
                $Result = Get-OSDriverInf -Path $Path
            } catch {
                $script:Logger.Error("Exception while calling 'Get-OSDriverInf'")
                $script:Logger.Error("$($_.ToString())")
            }

            if ($null -eq $Result) {
                # Fall back to Get-WindowsDriver
                $DriverInfo = Get-WindowsDriver -Online -Driver $Path
                try {
                    if ($null -ne $DriverInfo) {
                        $First = $DriverInfo | Select-Object -First 1

                        # Get SourceDiskFiles
                        $DriverSourceFiles = Get-DriverSourceDiskFile -Path $Path.ToString() -Verbose:$false
                        $Result = [PSCustomObject]@{
                            DriverFile = $Driver.FullName
                            CatalogFile = ($First.CatalogFile)
                            ClassName = ($First.ClassName)
                            ClassGuid = ($First.ClassGuid)
                            ProviderName = ($First.ProviderName)
                            ManufacturerName = ($First.ManufacturerName)
                            Version = ($First.Version)
                            Date = ($First.Date)
                            SourceFiles = $DriverSourceFiles
                            HardwareIDs = @($DriverInfo  | ForEach-Object {
                                $HardwareID = [PSCustomObject]@{
                                    HardwareID = ($_.HardwareId)
                                    HardwareDescription = ($_.HardwareDescription)
                                    Architecture = ''
                                }
                                if ($_.Architecture -eq 0) {
                                    $HardwareID.Architecture = 'x86'
                                } elseif ($_.Architecture -eq 9) {
                                    $HardwareID.Architecture = 'x64'
                                } elseif ($_.Architecture -eq 6) {
                                    $HardwareID.Architecture = 'ia64'
                                }
                                $HardwareID
                            } | Group-Object  HardwareID, Architecture | ForEach-Object {$_.Group | Select-Object -First 1} | Sort-Object HardwareID)
                        }
                    }
                } catch {
                    $script:Logger.Error("Exception while calling 'Get-WindowsDriver -Online -Driver ""$Path""")
                    $script:Logger.Error("$($_.ToString())")
                }
            }

            if ($null -eq $Result) {
                $Logger.Error("Failed to get windows driver.")
            } else {
                $Result
            }

        } elseif ($Driver.Extension -eq '.json') {
            $script:Logger.Info("Get windows driver info from '$Path'")
            , (Read-PackageInfoFile -Path ($Driver.FullName))
        }
    }
}