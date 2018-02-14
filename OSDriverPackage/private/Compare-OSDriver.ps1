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

        # Specifies, if the Package Driver should be returned. A new property "Replace"
        # wil be added to the Package Driver objects.
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
        $Result = $false
        Write-Verbose "  Pkg Driver : $($PackageDriver.DriverFile)"
        $DriverVersion = New-Object System.Version ($PackageDriver.DriverInfo | Select-Object -First 1 -ExpandProperty Version)
        Write-Verbose "  Pkg Version: $DriverVersion"

        if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
            Write-Verbose '    Core Driver has an equal or higher version.'
            $Result = $true
        } else {
            Write-Verbose '    Core Driver has a lower version. Keep Package Driver.'
        }

        if ($Result){
            # Compare PNPIDs
            # Every PnP ID from the Package Driver should be supported by the Core Driver as well.
            $PkgPNPIDS = ($PackageDriver.DriverInfo | Select-Object -ExpandProperty HardwareID -Unique)
            foreach ($PnPID in $PkgPNPIDS){
                if ($CorePNPIDS -notcontains $PnPID){
                    Write-Verbose "    PNPID '$PnPID' is not supported by Core Driver. Keep Package Driver."
                    $Result = $false
                }
            }
            if ($Result) {
                Write-Verbose "    Core Driver supports all PnP IDs of the Package Driver."
            }
        }

        # Adjust output in pipeline
        if ($PassThru.IsPresent) {
            if ([bool]($PackageDriver.PSobject.Properties.Name -match "Replace")) {
                $PackageDriver.Replace = $Result
            } else {
                $PackageDriver | Add-Member -NotePropertyName 'Replace' -NotePropertyValue $Result
            }

            $PackageDriver
        } else {
            $Result
        }
    }

    end {
        Write-Verbose "Finished comparing Drivers."
    }
}