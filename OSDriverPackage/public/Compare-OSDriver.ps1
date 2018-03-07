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
    param(
        # Specifies the Core Driver.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$CoreDriver,

        # Specifies that should be compared
        [Parameter(Mandatory, ValueFromPipeline)]
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
        Write-Verbose "Start comparing drivers."
        if ($null -eq $CoreDriver.DriverFile) {
            # Handle inf files as well
            if ($CoreDriver -like '*.inf') {
                if (Test-Path -Path $CoreDriver) {
                    $CoreDriver = Get-OSDriver -Path $CoreDriver
                }
            }
        }
        Write-Verbose " Core Driver : $($CoreDriver.DriverFile)"
        $CoreVersion = New-Object System.Version ($CoreDriver.Version)
        Write-Verbose " Core Version: $CoreVersion"

        # Use Hashtables, as we might have to run multiple contains checks
        $CorePnPIDsx86 = @{}
        $CorePnPIDsx64 = @{}
        $CoreDriver.HardwareIDs | Where-Object {$_.Architecture -eq 'x86'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx86[$_]=$null}
        $CoreDriver.HardwareIDs | Where-Object {$_.Architecture -eq 'x64'} | Select-Object -ExpandProperty HardwareID | Get-CompatibleID | ForEach-Object {$CorePnPIDsx64[$_]=$null}
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
        $Replace = $false
        if ($null -eq $Driver.DriverFile) {
            # Handle inf files as well
            if ($Driver -like '*.inf') {
                if (Test-Path -Path $Driver) {
                    $Driver = Get-OSDriver -Path $Driver
                }
            }
        }
        Write-Verbose " Driver      : $($Driver.DriverFile)"
        $DriverVersion = New-Object System.Version ($Driver.Version)
        Write-Verbose " Drv Version : $DriverVersion"

        if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
            Write-Verbose '  Core Driver has an equal or higher version.'
            $Replace = $true
            $Version = $true
        } elseif ($IgnoreVersion.IsPresent) {
            Write-Verbose '  Core Driver has a lower version. Continue with PnP check as Version check was set to be ignored.'
            $Replace = $true
            $Version = $false
        } else {
            Write-Verbose '  Core Driver has a lower version. Keep Driver.'
            $Version = $false
        }

        if ($Replace){
            # Compare Hardware IDs
            # Every PnP ID from the Package Driver should be supported by the Core Driver.
            # Outdated HardwareID can be handled using IgnoreIDs.
            # TODO: Support for CompatibleIDs ?
            $MissingHardwareIDs = @{}
            $Driver.HardwareIDs | ForEach-Object {
                $HardwareID = $_.HardwareID
                if ([string]::IsNullOrEmpty($HardwareID)) {
                    Write-Warning "  Empty HardwareID: $_"
                } else {
                    # Make sure we check the appropriate architecture as well
                    if ((($_.Architecture -eq 'x64') -and (-Not($CorePNPIDSx64.ContainsKey($HardwareID)))) -or (($_.Architecture -eq 'x86') -and(-Not($CorePNPIDSx86.ContainsKey($HardwareID))))) {
                        if ($CriticalPnPIDs.Count -gt 0){
                            if ($CriticalPnPIDs.ContainsKey($HardwareID)) {
                                Write-Verbose "  HardwareID '$HardwareID' is not supported by Core Driver and defined as critical. Keep Driver."
                                $Replace = $false
                            } else {
                                Write-Verbose "  HardwareID '$HardwareID' is not supported by Core Driver but is defined as non-critical."
                            }
                        } elseif  (($IgnorePnPIDs.ContainsKey($HardwareID)) -and (($CriticalPnPIDs.Count -eq 0) -or (-not($CriticalPnPIDs.ContainsKey($HardwareID))))) {
                            Write-Verbose "  HardwareID '$HardwareID' is not supported by Core Driver but is defined as non-critical."
                        } else {
                            # Get compatible Hardware IDs
                            $CompatibleIDs = Get-CompatibleID -HardwareID $HardwareID

                            $CompatibleIDFound = $False
                            foreach ($CompatibleID In $CompatibleIDs) {
                                if ((($_.Architecture -eq 'x64') -and ($CorePNPIDSx64.ContainsKey($HardwareID))) -or (($_.Architecture -eq 'x86') -and($CorePNPIDSx86.ContainsKey($HardwareID)))) {
                                    Write-Verbose "  HardwareID '$HardwareId' is supported by compatible HardwareID '$CompatibleID'."
                                    $CompatibleIDFound = $true
                                    break
                                }
                            }

                            if (-Not($CompatibleIDFound)) {
                                Write-Verbose "  HardwareID '$HardwareID' is not supported by Core Driver. Keep Driver."
                            }
                        }
                    } else {
                        Write-Verbose "  HardwareID '$HardwareID' is supported by Core Driver."
                    }

                    if (-Not($Replace)) {
                        $MissingHardwareIDs[$_] = $_.HardwareDescription
                    }
                }
            }

            if ($Replace) {
                if ($CriticalPnPIDs.Count -eq 0) {
                    Write-Verbose "  Core Driver supports all Hardware IDs of the Driver."
                } else {
                    Write-Verbose "  Core Driver supports all critical Hardware IDs of the Driver."
                }
            }
        }

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
                $Driver.MissingHardwareIDs = ($MissingHardwareIDs.Keys)
            } else {
                $Driver | Add-Member -NotePropertyName 'MissingHardwareIDs' -NotePropertyValue ($MissingHardwareIDs.Keys)
            }

            $Driver
        } else {
            $Replace
        }
    }

    end {
        Write-Verbose "Finished comparing Drivers."
    }
}