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
        [Parameter(Mandatory, Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$CoreDriverPackage,

        # Specifies the Driver Package that should be compared
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_.DriverPackage) -and (((Get-Item $_.DriverPackage).Extension -eq '.cab') -or ((Get-Item $_.DriverPackage).Extension -eq '.zip'))})]
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
        [hashtable]$Mappings = @{},

        # Specifies if the Driver Package is targetting a single architecture only or all
        [ValidateSet('All', 'x86', 'x64', 'ia64')]
        [string]$Architecture = 'All'
    )

    begin {
        $script:Logger.Trace("Compare driver package ('DriverPackage':'$($DriverPackage | ConvertTo-Json -Depth 1)'")

        # Ensure drivers are loaded
        if ($null -eq $DriverPackage.Drivers) {
            $DriverPackage.Drivers = (Get-OSDriver -Path ($DriverPackage.DriverPackage -replace '.txt', '.json'))
        }

        # Get Mappings from Driver Package definitions
        if ($DriverPackage.Definition.Contains('Mappings')){
            foreach ($Mapping in ($DriverPackage.Definition.Mappings.Keys)) {
                if ($Mapping -notlike 'Comment_*') {
                    $script:Logger.Debug("Use mapping '$Mapping' = '$($DriverPackage.Definition.Mappings[$Mapping])'.")
                    $Mappings[$Mapping] = $DriverPackage.Definition.Mappings[$Mapping]
                }
            }
        }

        if ($DriverPackage.Definition.Contains('HardwareIDs')){
            foreach ($IgnoreID in ($DriverPackage.Definition.HardwareIDs.Keys)) {
                $IgnoreValue = $DriverPackage.Definition.HardwareIDs[$IgnoreID]
                if ($IgnoreValue -eq 'Ignore') {
                    $script:Logger.Debug("Add HardwareID '$IgnoreID' to list of IgnoredIDs.")
                    $IgnoreIDs += $IgnoreID
                }
            }
        }

        if (-not($IgnoreVersion)) {
            # Check if IgnoreVersion is set for the Driver Package
            if ($DriverPackage.Definition.Contains('OSDrivers')){
                if ($DriverPackage.Definition.OSDrivers.Contains('IgnoreVersion')){
                    if (($DriverPackage.Definition.OSDrivers['IgnoreVersion'] -eq 'Yes') -or ($DriverPackage.Definition.OSDrivers['IgnoreVersion'] -eq 'True')) {
                        $script:Logger.Debug("Driver package is configured to ignore versions.")
                        $IgnoreVersion = $true
                    }
                }
            }
        }
    }

    process {


        foreach ($CorePkg in $CoreDriverPackage){
            $script:Logger.Trace("Compare driver package ('CoreDriverPackage':'$($CorePkg | ConvertTo-Json -Depth 1)'")
            $script:Logger.Info("Comparing driver package '$($DriverPackage.DriverPackage)' with '$($CorePkg.DriverPackage)'")

            $script:Logger.Debug("Core Driver Package : $($CorePkg.DriverPackage)")

            # Ensure drivers are loaded
            if ($null -eq $CorePkg.Drivers) {
                $CorePkg.Drivers = (Get-OSDriver -Path ($CorePkg.DriverPackage -replace '.txt', '.json'))
            }

            # Get Mappings from Core Driver Package definitions
            if ($CorePkg.Definition.Contains('Mappings')){
                foreach ($Mapping in ($CorePkg.Definition.Mappings.Keys)) {
                    if ($Mapping -notlike 'Comment_*') {
                        $script:Logger.Debug("Use mapping '$Mapping' = '$($CorePkg.Definition.Mappings[$Mapping])'.")
                        $Mappings[$Mapping] = $CorePkg.Definition.Mappings[$Mapping]
                    }
                }
            }

            if ($CorePkg.Definition.Contains('HardwareIDs')){
                foreach ($IgnoreID in ($CorePkg.Definition.HardwareIDs.Keys)) {
                    $IgnoreValue = $CorePkg.Definition.HardwareIDs[$IgnoreID]
                    if ($IgnoreValue -eq 'Ignore') {
                        $script:Logger.Debug("Adding HardwareID '$IgnoreID' to list of IgnoredIDs.")
                        $IgnoreIDs += $IgnoreID
                    }
                }
            }

            # Check if IgnoreVersion is set for the Core Package
            if ($CorePkg.Definition.Contains('OSDrivers')){
                if ($CorePkg.Definition.OSDrivers.Contains('IgnoreVersion')){
                    if (($CorePkg.Definition.OSDrivers['IgnoreVersion'] -eq 'Yes') -or ($CorePkg.Definition.OSDrivers['IgnoreVersion'] -eq 'True')) {
                        $script:Logger.Debug("Core Driver package is configured to ignore versions.")
                        $IgnoreCoreVersion = $true
                    }
                }
            }

            if ($Architecture -ne 'All') {
                $PkgDrivers = $DriverPackage.Drivers | Where-Object {((($_.HardwareIDs | Group-Object -Property 'Architecture' | Where-Object {$_.Name -eq "$Architecture"}).Count -gt 0) -and (-Not($_.Replace)))}
            } else {
                $PkgDrivers = $DriverPackage.Drivers | Where-Object {-Not($_.Replace)}
            }

            foreach ($Driver in $PkgDrivers) {
                $script:Logger.Debug("Current driver : $($Driver.Driverfile)")
                $Drivername = (Split-Path $Driver.DriverFile -Leaf)
                $CoreDriver = $null

                $CoreDrivers = $CorePkg.Drivers | Foreach-Object {
                    $CoreDriverName = (Split-Path $_.DriverFile -Leaf)

                    $Found = $false
                    if ($DriverName -eq $CoreDriverName) {
                        $Found = $true
                        $CoreDriver = $_
                        $_
                        $script:Logger.Trace("Found matching driver '$($_.DriverFile)'.")
                    } elseif ($Mappings.ContainsKey($CoreDriverName)) {
                        foreach ($Mapping in ($Mappings[$CoreDrivername]) -split ',') {
                            if ($DriverName -like $Mapping) {
                                $Found = $true
                                $_
                                $script:Logger.Trace("Found matching driver '$($_.DriverFile)'.")
                            }
                        }
                    } elseif ($Mappings.ContainsKey($DriverName)) {
                        foreach ($Mapping in ($Mappings[$DriverName]) -split ',') {
                            if ($DriverName -like $Mapping) {
                                $Found = $true
                                $_
                                $script:Logger.Trace("Found matching driver '$($_.DriverFile)'.")
                            }
                        }
                    }

                    if ((-Not($Found)) -and ($Driver.ClassName -eq $_.ClassName) -and ($Driver.ProviderName -eq $_.ProviderName)) {
                        $_
                        $script:Logger.Trace("Found matching driver '$($_.DriverFile)'.")
                    }
                }

                if ($CoreDrivers.Count -eq 0) {
                    $script:Logger.Debug("No related driver in '$($DriverPackage.DriverPackage)'.")
                } else {
                    # Prepare Drivers
                    $PackageHardwareIDs = @()
                    if ($IgnoreVersion -or $IgnoreCoreVersion) {
                        # Version is irrelevant. Get a unique list of Hardware IDs supported by the Core Drivers related to this Driver
                        $PackageHardwareIDs = $CoreDrivers | Select-Object -ExpandProperty HardwareIDs | Group-Object -Property HardwareID, Architecture | ForEach-Object {$_.Group | Select-Object -First 1}
                    } else {
                        $DriverVersion = New-Object System.Version ($Driver.Version)
                        $PackageHardwareIDs = $CoreDrivers | Foreach-Object {
                            $CoreVersion = New-Object System.Version ($_.Version)
                            if ($DriverVersion.CompareTo($CoreVersion) -le 0) {
                                $_
                            }
                        } | Select-Object -ExpandProperty HardwareIDs | Group-Object -Property HardwareID, Architecture | ForEach-Object {$_.Group | Select-Object -first 1}
                    }

                    if ($null -eq $CoreDriver) {
                        $CoreDriver = $CoreDrivers | Select-Object -First 1
                    }
                    Compare-OSDriver -CoreDriver $CoreDriver -Driver $Driver -PassThru -CriticalIDs $CriticalIDs -IgnoreIDs $IgnoreIDs -IgnoreVersion:($IgnoreVersion -or $IgnoreCoreVersion) -PackageHardwareIDs $PackageHardwareIDs
                }
            }
        }
    }

    end {
        # Return list of Result objects. Original DriverPackage will be updated as well.
        $Result = $DriverPackage.Drivers | Where-Object {$null -ne $_.Replace}
        if ($Result.Count -gt 0) {
            $script:Logger.Info("Found $($Result.Count) drivers that can be removed.")
        } else {
            $script:Logger.Info("Found no drivers that can be removed.")
        }

    }
}