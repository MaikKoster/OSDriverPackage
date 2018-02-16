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


        # Specifies, if the Package Driver should be returned.
        # Helpful if used within a pipeline.
        [switch]$PassThru
    )

    begin {
        Write-Verbose "Start comparing drivers."
        Write-Verbose " Core Driver : $($CoreDriver.DriverFile)"
        $CoreVersion = New-Object System.Version ($CoreDriver.DriverInfo | Select-Object -First 1 -ExpandProperty Version)
        Write-Verbose " Core Version: $CoreVersion"
        $CorePNPIDS = ($CoreDriver.DriverInfo | Select-Object -ExpandProperty HardwareID -Unique)
    }

    process {
        $Replace = $false

        Write-Verbose "  Pkg Driver : $($PackageDriver.DriverFile)"
        $DriverVersion = New-Object System.Version ($PackageDriver.DriverInfo | Select-Object -First 1 -ExpandProperty Version)
        Write-Verbose "  Pkg Version: $DriverVersion"

        if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
            Write-Verbose '    Core Driver has an equal or higher version.'
            $Replace = $true
            $Version = $true
        } else {
            Write-Verbose '    Core Driver has a lower version. Keep Package Driver.'
        }

        if ($Result){
            # Compare PNPIDs
            # Every PnP ID from the Package Driver should be supported by the Core Driver as well.
            $PkgPNPIDS = ($PackageDriver.DriverInfo | Select-Object -ExpandProperty HardwareID -Unique)
            $MissingPNPIDs = @()
            foreach ($PnPID in $PkgPNPIDS){
                if ($CorePNPIDS -notcontains $PnPID){
                    $MissingPNPIDs += $PnPID
                    Write-Verbose "    PNPID '$PnPID' is not supported by Core Driver. Keep Package Driver."
                    $Replace = $false
                } else {
                    Write-Verbose "    PNPID '$PnPID' is supported by Core Driver."
                }
            }
            if ($Replace) {
                Write-Verbose "    Core Driver supports all PnP IDs of the Package Driver."
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

            if ([bool]($PackageDriver.PSobject.Properties.Name -match "MissingPNPIDs")) {
                $PackageDriver.MissingPNPIDs = $MissingPNPIDs
            } else {
                $PackageDriver | Add-Member -NotePropertyName 'MissingPNPIDs' -NotePropertyValue $MissingPNPIDs
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