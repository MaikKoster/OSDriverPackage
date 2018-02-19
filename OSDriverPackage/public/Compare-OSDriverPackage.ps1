Function Compare-OSDriverPackage {
    <#
    .Synopsis
        Checks the supplied Driver Package against the Core Driver Package.

    .Description
        The Compare-OSDriverPackage CmdLet compares Driver Packages. The supplied Driver Package will be
        evaluated against the supplied Core Driver Package.

        It uses Compare-OSDriver to compare related Drivers in each Driver Package. Drivers will be matched
        by the name of the inf file. To compare drivers where a vendor uses different filenames for the same
        driver, you can use Compare-OSDrive to overwrite this standard behaviour individuall.

        Comparison logic is based on the implementation of Compare-OSDriver:
        If it has the same or lower version as the Core Driver, and all Hardware IDs are handled by the Core
        Driver as well, the Replace property will be set to $true to indicate, that it can most likely be
        replaced by the Core Driver. If not, it will return $false.

        Additional information about the evaluation will be added to each Driver object to allow further
        actions. The new poperties will be:

        - Replace: will be set to $true, if the Driver can be safely replaced by the Core Driver. $False if not.
        - LowerVersion: will be set to $true, if the Core Driver has a higher version. $false, if not.
        - MissingHardwareIDs: List of Hardware IDs, that are not referenced by the Core Driver.
    #>

    [CmdletBinding()]
    param(
        # Specifies the Core Driver.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$CoreDriverPackage,

        # Specifies the Driver Package that should be compared
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_.DriverPackage) -and ((Get-Item $_.DriverPackage).Extension -eq '.cab')})]
        [PSCustomObject]$DriverPackage,

        # Specifies a list of critical PnP IDs, that must be covered by the Core Drivers
        # if found within the Package Driver.
        [string[]]$CriticalIDs = @(),

        # Specifies a list of PnP IDs, that can be safely ignored during the comparison.
        [string[]]$IgnoreIDs = @(),

        # Specifies, if the Driver version should be ignored.
        [switch]$IgnoreVersion,

        # Specifies a list of known mappings of Driver inf files.
        # Some computer vendors tend to rename the original inf files as part of their customization process
        [hashtable]$Mappings = @{}
    )

    begin {
        Write-Verbose "Start comparing Driver Package."
    }

    process {
        foreach ($CorePkg in $CoreDriverPackage){
            Write-Verbose " Core Driver Package : $($CorePkg.DriverPackage)"
            #foreach ($DrvPkg in $DriverPackage) {
                Write-Verbose "  Driver Package : $($DriverPackage.DriverPackage)"
                foreach ($CoreDriver in $CorePkg.Drivers) {
                    Write-Verbose "    Core Driver : $($CoreDriver.DriverFile)"
                    $CoreDriverName = (Split-Path $CoreDriver.DriverFile -Leaf)
                    #$DriversToProcess = $DriverPackage.Drivers | Where-Object {(Split-Path -Path ($_.DriverFile) -Leaf) -eq $CoreDriverName}
                    $DriversToProcess = $DriverPackage.Drivers | Foreach-Object {
                        $DriverName = Split-Path -Path ($_.DriverFile) -Leaf

                        if ($DriverName -eq $CoreDriverName) {
                            $_
                        } elseif ($Mappings.ContainsKey($CoreDriverName)) {
                            foreach ($Mapping in ($Mappings[$CoreDrivername]) -split ',') {
                                if ($DriverName -eq $Mapping) {
                                    $_
                                }
                            }
                        } elseif ($Mappings.ContainsKey($DriverName)) {
                            foreach ($Mapping in ($Mappings[$DriverName]) -split ',') {
                                if ($DriverName -eq $Mapping) {
                                    $_
                                }
                            }
                        }

                        Where-Object {(Split-Path -Path ($_.DriverFile) -Leaf) -eq $CoreDriverName}
                    }
                    if ($null -eq $DriversToProcess) {
                        Write-Verbose "    No related Driver in '$($DriverPackage.DriverPackage)'."
                    } else {
                        $DriversToProcess | Compare-OSDriver -CoreDriver $CoreDriver -PassThru -CriticalIDs $CriticalIDs -IgnoreIDs $IgnoreIDs -IgnoreVersion:$IgnoreVersion
                    }
                }
            #}
        }
    }

    end {
        Write-Verbose "Finished comparing Driver Package."
    }
}