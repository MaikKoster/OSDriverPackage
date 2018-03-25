function Get-OSDriverPackage {
    <#
    .SYNOPSIS
        Gets a Driver Package.

    .DESCRIPTION
        The Get-OSDriverPackage CmdLet gets one or multiple Driver Packages based on the supplied conditions.
        If no value for a specific criteria has been supplied, it will be ignored.
        Multiple criteria will be treated as AND.
        Multiple values for a criteria will be treated as OR.

    .NOTES

    #>
    [CmdletBinding()]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders will be returned
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Filters the Driver Packages by Name
        # Wildcards are allowed e.g.
        [string[]]$Name,

        # Filters the Driver Packages by a generic tag.
        # Can be used to .e.g identify specific Core Packages
        [string[]]$Tag,

        # Filters the Driver Packages by OSVersion
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        # Wildcards are allowed e.g. Win*-x64
        [string[]]$OSVersion,

        # Filters the Driver Packages by Architecture
        # Recommended to use tags as e.g. x64, x86.
        [string[]]$Architecture,

        # Filters the Driver Packages by Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Dell*
        [string[]]$Make,

        # Filters the Driver Packages by Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Latitude*
        [string[]]$Model,

        # Specifies a list of HardwareIDs, that should be used to identify related Driver Package(s).
        [string[]]$HardwareIDs,

        # Specifies if the WQL command specified in the driver package definition file should be
        # executed to identify matching Driver Package(s).
        [switch]$UseWQL
    )

    begin {
        # Add HardwareIDs and all compatible IDs into a Hashtable to speed up search
        $PnPIDs = @{}
        if ($HardwareIDs.Count -gt 0) {
            $HardwareIDs | Get-CompatibleID | ForEach-Object {$PnPIDs[$_]=$null}
        }
    }

    process {
        $script:Logger.Trace("Get driver package ('Path':'$Path', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')'  ")

        # Generic logic
        $Root = Get-Item -Path ($Path.Trim("\"))

        if ($Root.PSIsContainer) {
            $script:Logger.Debug('Path supplied. Check if there is a driver package with the same name.')
            if (Test-Path "$($Root.FullName).cab") {
                $Root = Get-Item -Path "$($Root.FullName).cab"
            } elseif (Test-Path "$($Root.FullName).zip") {
                $Root = Get-Item -Path "$($Root.FullName).zip"
            }
        } elseif ($Root.Extension -eq '.txt'){
            $script:Logger.Debug('Driver package defition file supplied. Using driver package file name.')
            if (Test-Path ($Root.FullName -replace '.txt', '.cab')) {
                $Root = Get-Item ($Root.FullName -replace '.txt', '.cab')
            } elseif (Test-Path ($Root.FullName -replace '.txt', '.zip')) {
                $Root = Get-Item ($Root.FullName -replace '.txt', '.zip')
            }
        }

        if (($Root.Extension -eq '.zip') -or ($Root.Extension -eq '.cab')) {
            $script:Logger.Info("Get driver package '$($Root.Fullname)'.")

            $DefinitionFileName = $Root.FullName -replace "$($Root.Extension)", '.txt'
            $InfoFileName = $Root.FullName -replace "$($Root.Extension)", '.json'

            if (Test-Path $DefinitionFileName) {
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            } else {
                $script:Logger.Warn("No definition file for driver package '$($Root.Name)' found. Creating stub.")
                $script:Logger.Warn("Please update manually so filters can be applied properly.")
                New-OSDriverPackageDefinition -DriverPackagePath $Root.FullName
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            }

            $script:Logger.Info("Evaluating criteria.")

            if ($null -ne $Definition) {
                $Section = $Definition['OSDrivers']
                if ($null -ne $Section) {
                    if (-Not(Compare-Criteria -Section $Section -Filter $OSVersion -Include 'OSVersion')) {
                        $IncludeDriverPackage = $false
                    } elseif (-Not(Compare-Criteria -Section $Section -Filter $Architecture -Include 'Architecture')) {
                        $IncludeDriverPackage = $false
                    } elseif (-Not(Compare-Criteria -Section $Section -Filter $Tag -Include 'Tag')) {
                        $IncludeDriverPackage = $false
                    } elseif (-Not(Compare-Criteria -Section $Section -Filter $Make -Include 'Make')) {
                        $IncludeDriverPackage = $false
                    } elseif (-Not(Compare-Criteria -Section $Section -Filter $Model -Include 'Model')) {
                        $IncludeDriverPackage = $false
                    } else {
                        $IncludeDriverPackage = $true
                    }
                } else {
                    $script:Logger.Warn("Invalid definition file for driver package '$($Root.Name)'. Skipping driver package.")
                }

                # Only search for Hardware IDs if Driver Package hasn't been matched yet.
                if (-Not($IncludeDriverPackage)) {
                    if ($PnPIDs.Count -gt 0) {
                        # Get list of Driver Package Hardware IDs
                        $PkgHardwareIDs = $Definition['PNPIDS']
                        if ($null -ne $PkgHardwareIDs) {
                            $script:Logger.Debug('Searching for Hardware IDs in driver package definition file.')
                            foreach ($PkgHardwareID in $PkgHardwareIDs.Keys) {
                                # Get compatible Hardware IDs
                                $CompatibleIDs = Get-CompatibleID -HardwareID $PkgHardwareID

                                foreach ($CompatibleID In $CompatibleIDs) {
                                    if ($PnPIDS.ContainsKey($CompatibleID)) {
                                        $script:Logger.Debug("HardwareID '$PkgHardwareID' is compatible with supplied list of HardwareIDs.")
                                        $IncludeDriverPackage = $true
                                        break
                                    }
                                }
                            }
                        } else {
                            $script:Logger.Debug('No Hardware IDs specified in driver package definition file.')
                        }
                    }
                }

                # Only execute WQL if Driver Package hasn't been matched yet.
                if (-Not($IncludeDriverPackage)) {
                    if ($UseWQL.IsPresent) {
                        # Get list of WQL queries
                        $WQLQueries = $Definition['WQL']
                        if ($null -ne $WQLQueries) {
                            $script:Logger.Debug('Executing WQL queries from driver package definition file.')
                            # As WQL queries are treated as comments. So the query is stored in the value
                            foreach ($WQLQuery in $WQLQueries.Values) {
                                $Result = Get-CimInstance -Query "$WQLQuery"

                                if ($null -ne $Result) {
                                    $script:Logger.Debug("WQL query '$WQLQuery' returned a result.")
                                    $IncludeDriverPackage = $true
                                        break
                                }
                            }
                        } else {
                            $script:Logger.Debug('No WQL queries defined in package definition file.')
                        }
                    }
                }
            } else {
                $script:Logger.Warn("Invalid definition file for driver package '$($Root.Name)'. Skipping driver package.")
            }

            if ($IncludeDriverPackage) {
                $script:Logger.Info("Driver package matches the supplied criteria.")
                # Create Driver Info file if necessary
                if (-Not(Test-Path $InfoFileName)) {
                    Read-OSDriverPackage -Path $Root
                }

                [PSCustomObject]@{
                    DriverPackage = ($Root.FullName)
                    DefinitionFile = $DefinitionFileName
                    Definition = $Definition
                    Drivers = (Get-OSDriver -Path $InfoFileName)
                }
            } else {
                $script:Logger.Info("Driver package doesn't match the supplied criteria.")
            }
        } else {
            $script:Logger.Debug("Searching for driver packages in '$Path'.")

            $GetParams = @{
                Path = $Path
                Include = @('*.cab', '*.zip')
                Recurse = $true
                File = $true
            }
            if (-Not([string]::IsNullOrEmpty($Name))) {
                $GetParams.Filter = $Name
            }
            Get-ChildItem @GetParams| Get-OSDriverPackage
        }
    }

}