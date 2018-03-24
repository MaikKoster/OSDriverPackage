Function Compare-OSDriver {
    <#
    .Synopsis
        Checks if the supplied Driver can be replaced by the supplied Core Driver.

    .Description
        The Compare-OSDriver CmdLet compares two drivers. The supplied driver will be evaluated
        against the supplied Core Driver.

        If it has the same or lower version as the Core Driver, and all Hardware IDs are handled by the Core
        Driver as well, the function, it will return $true to indicate, that it can most likely be
        replaced by the Core Driver. If not, it will return $false.

        If PassThru is supplied, additional information about the evaluation will be added to the Package
        Driver object and passed thru for further actions. The new poperties will be:
        Replace: will be set to $true, if the Driver can be safely replaced by the Core Driver. $False if not.
        LowerVersion: will be set to $true, if the Core Driver has a higher version. $false, if not.
        MissingHardwareIDs: List of Hardware IDs, that are not referenced by the Core Driver.
    #>

    [CmdletBinding()]
    [OutputType([boolean])]
    param(
        # Specifies the Core Driver.
        [Parameter(Mandatory, Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$CoreDriver,

        # Specifies the driver that should be compared
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("PackageDriver")]
        [PSCustomObject]$Driver,

        # Specifies a list of critical PnP IDs, that must be covered by the Core Drivers
        # if found within the Package Driver.
        [string[]]$CriticalIDs = @(),

        # Specifies a list of PnP IDs, that can be safely ignored during the comparison.
        [string[]]$IgnoreIDs = @(),

        # Specifies a list of HardwareIDs from the Driver Package that contains the supplied Driver.
        # Some vendors create 'merged' drivers based on individual drivers from the original manufacturer.
        # As those 'merged' drivers whould always be missing Hardware IDs, as they were orignally supplied
        # by different, individual drivers, all Drivers within a Driver Package should be seen as an entity.
        [PSCustomObject[]]$PackageHardwareIDs = @(),

        # Specifies, if the Driver version should be ignored.
        [switch]$IgnoreVersion,

        # Specifies, if the Package Driver should be returned.
        # Helpful if used within a pipeline.
        [switch]$PassThru
    )

    begin {
        $script:Logger.Trace("Start comparing drivers.")

        # Use Hashtables, as we might have to run multiple contains checks
        $CorePnPIDsx86 = @{}
        $CorePnPIDsx64 = @{}
        if ($PackageHardwareIDs.Count -gt 0) {
            $PackageHardwareIDs | Where-Object {$_.Architecture -eq 'x86'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx86[$_]=$null}
            $PackageHardwareIDs | Where-Object {$_.Architecture -eq 'x64'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx64[$_]=$null}
        }

        $CriticalPnPIDs = @{}
        $CriticalIDs | ForEach-Object {$CriticalPnPIDs[$_]=$null}
        $IgnorePnPIDs = @{}
        $IgnoreIDs | ForEach-Object {$IgnorePnPIDs[$_]=$null}
    }

    process {
        $script:Logger.Trace("compare driver ('Driver':'$($Driver | ConvertTo-Json -Depth 1)', 'CoreDriver':'$($CoreDriver | ConvertTo-Json -Depth 1)'")

        $Replace = $false

        if ($Driver.Replace) {
            # This driver has already been properly evaluated
            # skip any further evaluation
            $script:Logger.Debug("Skipping Driver '$($Driver.Driverfile)', as it has already been evaluated before and can be replaced.")
            $Driver
        } else {
            if ($null -eq $CoreDriver.DriverFile) {
                # Handle inf files as well
                if ($CoreDriver -like '*.inf') {
                    if (Test-Path -Path $CoreDriver) {
                        $CoreDriver = Get-OSDriver -Path $CoreDriver
                    }
                }
            }

            if ($null -ne $CoreDriver.DriverFile) {
                $script:Logger.Debug("Core Driver : $($CoreDriver.DriverFile)")
                $CoreVersion = New-Object System.Version ($CoreDriver.Version)
                $script:Logger.Debug("Core Version: $CoreVersion")

                # Add Core Driver IDs.
                $CoreDriver.HardwareIDs | Where-Object {$_.Architecture -eq 'x86'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx86[$_]=$null}
                $CoreDriver.HardwareIDs | Where-Object {$_.Architecture -eq 'x64'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx64[$_]=$null}


                if ($null -eq $Driver.DriverFile) {
                    # Handle inf files as well
                    if ($Driver -like '*.inf') {
                        if (Test-Path -Path $Driver) {
                            $Driver = Get-OSDriver -Path $Driver
                        }
                    }
                }

                if ($null -ne $Driver.DriverFile) {
                    $script:Logger.Debug("Driver      : $($Driver.DriverFile)")
                    $DriverVersion = New-Object System.Version ($Driver.Version)
                    $script:Logger.Debug("Drv Version : $DriverVersion")

                    if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
                        $script:Logger.Debug('Core driver has an equal or higher version.')
                        $Replace = $true
                        $Version = $true
                    } elseif ($IgnoreVersion.IsPresent) {
                        $script:Logger.Debug('Core driver has a lower version. Continue with PnP check as version check was set to be ignored.')
                        $Replace = $true
                        $Version = $false
                    } else {
                        $script:Logger.Debug('Core driver has a lower version. Keep driver.')
                        $Version = $false
                    }

                    # Always compare the Hardware IDs as well.
                    # This is to cover older hardware no longer supported by the newer version but still supported in some other core package
                    #if ($Replace){
                        # Compare Hardware IDs
                        # Every PnP ID from the Package Driver should be supported by the Core Driver.
                        # Outdated HardwareID can be handled using IgnoreIDs.
                        $MissingHardwareIDs = @{}
                        $Driver.HardwareIDs | ForEach-Object {
                            $HardwareID = $_.HardwareID
                            if ([string]::IsNullOrEmpty($HardwareID)) {
                                $script:Logger.Warn("Empty HardwareID: $_")
                            } else {
                                $HardwareIDFound = $false
                                # Make sure we check the appropriate architecture as well
                                if ((($_.Architecture -eq 'x64') -and (-Not($CorePNPIDSx64.ContainsKey($HardwareID)))) -or (($_.Architecture -eq 'x86') -and(-Not($CorePNPIDSx86.ContainsKey($HardwareID))))) {
                                    if ($CriticalPnPIDs.Count -gt 0){
                                        if ($CriticalPnPIDs.ContainsKey($HardwareID)) {
                                            $script:Logger.Debug("HardwareID '$HardwareID' is not supported by core driver and defined as critical. Keep Driver.")
                                            $Replace = $false
                                        } else {
                                            $script:Logger.Debug("HardwareID '$HardwareID' is not supported by core driver but is defined as non-critical.")
                                        }
                                    } elseif  (($IgnorePnPIDs.ContainsKey($HardwareID)) -and (($CriticalPnPIDs.Count -eq 0) -or (-not($CriticalPnPIDs.ContainsKey($HardwareID))))) {
                                        $script:Logger.Debug("HardwareID '$HardwareID' is not supported by core driver but is defined as non-critical.")
                                    } else {
                                        # Get compatible Hardware IDs
                                        $CompatibleIDs = Get-CompatibleID -HardwareID $HardwareID

                                        foreach ($CompatibleID In $CompatibleIDs) {
                                            if ((($_.Architecture -eq 'x64') -and ($CorePNPIDSx64.ContainsKey($CompatibleID))) -or (($_.Architecture -eq 'x86') -and($CorePNPIDSx86.ContainsKey($CompatibleID)))) {
                                                $script:Logger.Debug("HardwareID '$HardwareId' is supported by compatible HardwareID '$CompatibleID'.")
                                                $HardwareIDFound = $true
                                                break
                                            }
                                        }

                                        if (-Not($HardwareIDFound)) {
                                            $script:Logger.Debug("HardwareID '$HardwareID' is not supported by core driver. Keep driver.")
                                            $Replace = $false
                                        }
                                    }
                                } else {
                                    $script:Logger.Debug("HardwareID '$HardwareID' is supported by core driver.")
                                    $HardwareIDFound = $true
                                }

                                if ($null -eq $Driver.MissingHardwareIDs) {
                                    if (-Not($HardwareIDFound)) {
                                        $MissingHardwareIDs[$_] = $_.HardwareDescription
                                    }
                                } else {
                                    # Driver had been processed before.
                                    # Don't add new missing hardware IDs, as all missing ones should be identified already.
                                    # Remove missing hardware IDs if possible.
                                    if ($HardwareIDFound) {

                                        #$Remove = $Driver.MissingHardwareIDs | Where-Object {$_.HardwareID -eq $}
                                        if ($Driver.MissingHardwareIDs -contains $_) {
                                            $script:Logger.Debug("Removing '$HardwareID' from list of missing hardware IDs.")
                                            $Driver.MissingHardwareIDs.Remove($_)
                                        }
                                    }
                                }

                            }
                        }

                        if ($Replace) {
                            if ($CriticalPnPIDs.Count -eq 0) {
                                $script:Logger.Debug("Core driver supports all hardware IDs of the driver.")
                            } else {
                                $script:Logger.Debug("Core driver supports all critical Hardware IDs of the driver.")
                            }
                        } else {
                            if ($null -ne $Driver.MissingHardwareIDs) {
                                if ($Driver.MissingHardwareIDs.Count -eq 0) {
                                    # All hardwareIDs are covered by some drivers from the Core package(s)
                                    $Replace = $true
                                    $script:Logger.Debug("Core driver(s) support all hardware IDs of the driver.")
                                }
                            }
                        }
                    #}

                    # Remove duplicates
                    $MissingHardwareIDs = $MissingHardwareIDs | Group-Object -Property HardwareID, Architecture | ForEach-Object {$_.Group | Select-Object -First 1} | Sort-Object HardwareID

                    # Adjust output in pipeline
                    if ($PassThru.IsPresent) {
                        if ([bool]($Driver.PSobject.Properties.Name -match "Replace")) {
                            $Driver.Replace = $Replace
                        } else {
                            $Driver | Add-Member -NotePropertyName 'Replace' -NotePropertyValue $Replace
                        }

                        if ([bool]($Driver.PSobject.Properties.Name -match "LowerVersion")) {
                            $Driver.LowerVersion = $Version
                        } else {
                            $Driver | Add-Member -NotePropertyName 'LowerVersion' -NotePropertyValue $Version
                        }

                        if ([bool]($Driver.PSobject.Properties.Name -match "MissingHardwareIDs")) {
                            #$Driver.MissingHardwareIDs = ($MissingHardwareIDs.Keys)
                        } else {
                            $Driver | Add-Member -NotePropertyName 'MissingHardwareIDs' -NotePropertyValue  ([System.Collections.ArrayList]($MissingHardwareIDs.Keys))
                        }

                        # Don't drop Driver back to pipeline. The original object should have been updated.
                        # $Driver
                    } else {
                        $Replace
                    }
                } else {
                    $script:Logger.Error("Invalid driver supplied. '$Driver'")
                    Write-Error "Invalid Driver supplied. '$Driver'"
                    $false
                }
            } else {
                $script:Logger.Error("Invalid core driver supplied. '$CoreDriver'")
                Write-Error "Invalid core driver supplied. '$CoreDriver'"
                $false
            }
        }
    }
}