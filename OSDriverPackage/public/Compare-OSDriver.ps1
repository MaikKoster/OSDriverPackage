Function Compare-OSDriver {
    <#
    .Synopsis
        Checks if the supplied Driver can be replaced by the supplied Core Driver.

    .Description
        The Compare-OSDriver CmdLet compares two drivers. The supplied driver will be evaluated
        against the supplied Core Driver.

        If it has the same or lower version as the Core Driver, and all PNPIDs are handled by the Core
        Driver as well, the function, it will return $true to indicate, that it can most likely be
        replaced by the Core Driver. If not, it will return $false.

        If PassThru is supplied, additional information about the evaluation will be added to the Package
        Driver object and passed thru for further actions. The new poperties will be:
        Replace: will be set to $true, if the Driver can be safely replaced by the Core Driver. $False if not.
        LowerVersion: will be set to $true, if the Core Driver has a higher version. $false, if not.
        MissingPnPIDs: List of PnPIDs, that are not referenced by the Core Driver.
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
        [Alias("Driver")]
        [PSCustomObject]$PackageDriver,

        # Specifies a list of critical PnP IDs, that must be covered by the Core Drivers
        # if found within the Package Driver.
        [string[]]$CriticalIDs = @(),

        # Specifies a list of PnP IDs, that can be safely ignored during the comparison.
        [string[]]$IgnoreIDs = @(),

        # Specifies, if the Driver version should be ignored.
        [switch]$IgnoreVersion,

        # Specifies, if the Package Driver should be returned.
        # Helpful if used within a pipeline.
        [switch]$PassThru
    )

    begin {
        Write-Verbose "Start comparing drivers."
        Write-Verbose " Core Driver : $($CoreDriver.DriverFile)"
        $CoreVersion = New-Object System.Version ($CoreDriver.DriverVersion)
        Write-Verbose " Core Version: $CoreVersion"

        # Use Hashtables, as we might have to run multiple contains checks
        $CorePnPIDs = @{}
        $CoreDriver.HardwareIDs | Select-Object -ExpandProperty HardwareID | ForEach-Object {$CorePnPIDs[$_]=$null}
        $CriticalPnPIDs = @{}
        $CriticalIDs | ForEach-Object {$CriticalPnPIDs[$_]=$null}
        $IgnorePnPIDs = @{}
        $IgnoreIDs | ForEach-Object {$IgnorePnPIDs[$_]=$null}
    }

    process {
        $Replace = $false

        Write-Verbose "  Pkg Driver : $($PackageDriver.DriverFile)"
        $DriverVersion = New-Object System.Version ($PackageDriver.DriverVersion)
        Write-Verbose "  Pkg Version: $DriverVersion"

        if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
            Write-Verbose '    Core Driver has an equal or higher version.'
            $Replace = $true
            $Version = $true
        } elseif ($IgnoreVersion.IsPresent) {
            Write-Verbose '    Core Driver has a lower version. Continue with PnP check as Version check was set to be ignored.'
            $Replace = $true
            $Version = $false
        } else {
            Write-Verbose '    Core Driver has a lower version. Keep Package Driver.'
            $Version = $false
        }

        if ($Replace){
            # Compare PNPIDs
            # Every PnP ID from the Package Driver should be supported by the Core Driver as well.
            # TODO: Add logic for architecture
            # TODO: Support for CompatibleIDs ?
            $MissingPnPIDs = @{}
            $PackageDriver.HardwareIDs | Select-Object -ExpandProperty HardwareID | ForEach-Object {
                $PnPID = $_
                if (-Not($CorePNPIDS.ContainsKey($PnPID))){
                    $MissingPnPIDs[$_] = $null

                    if ($CriticalPnPIDs.ContainsKey($PnPID)) {
                        Write-Verbose "    PNPID '$_' is not supported by Core Driver and defined as critical. Keep Package Driver."
                        $Replace = $false
                    } elseif  (($IgnorePnPIDs.ContainsKey($_)) -and (($CriticalPnPIDs.Count -eq 0) -or (-not($CriticalPnPIDs.ContainsKey($PnPID))))) {
                        Write-Verbose "    PNPID '$_' is not supported by Core Driver but is defined as non-critical."
                    } else {
                        Write-Verbose "    PNPID '$_' is not supported by Core Driver. Keep Package Driver."
                        $Replace = $false
                    }
                } else {
                    Write-Verbose "    PNPID '$_' is supported by Core Driver."
                }
            }

            if ($Replace) {
                if ($CriticalPnPIDs.Count -eq 0) {
                    Write-Verbose "    Core Driver supports all PnP IDs of the Package Driver."
                } else {
                    Write-Verbose "    Core Driver supports all critical PnP IDs of the Package Driver."
                }
            }
        }

        # Adjust output in pipeline
        if ($PassThru.IsPresent) {
            if ([bool]($PackageDriver.PSobject.Properties.Name -match "Replace")) {
                $PackageDriver.Replace = $Replace
            } else {
                $PackageDriver | Add-Member -NotePropertyName 'Replace' -NotePropertyValue $Replace
            }

            if ([bool]($PackageDriver.PSobject.Properties.Name -match "LowerVersion")) {
                $PackageDriver.LowerVersion = $Version
            } else {
                $PackageDriver | Add-Member -NotePropertyName 'LowerVersion' -NotePropertyValue $Version
            }

            if ([bool]($PackageDriver.PSobject.Properties.Name -match "MissingPnPIDs")) {
                $PackageDriver.MissingPnPIDs = ($MissingPnPIDs.Keys)
            } else {
                $PackageDriver | Add-Member -NotePropertyName 'MissingPnPIDs' -NotePropertyValue ($MissingPnPIDs.Keys)
            }

            $PackageDriver
        } else {
            $Replace
        }
    }

    end {
        Write-Verbose "Finished comparing Drivers."
    }
}