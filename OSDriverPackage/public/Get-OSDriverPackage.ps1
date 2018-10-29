function Get-OSDriverPackage {
    <#
    .SYNOPSIS
        Gets a Driver Package.

    .DESCRIPTION
        The Get-OSDriverPackage CmdLet gets one or multiple Driver Packages based on the supplied conditions.
        If no value for a specific criteria has been supplied, it will be ignored.
        Multiple criteria will be treated as AND.
        Multiple values for the same criteria will be treated as OR.

    .NOTES
        A Driver Package is defined by the Driver Package Definition file ({DriverPackageName}.def). To allow for
        a performant selection process, only def files with an 'OSDriverPackage' section will be treated as valid Driver Packages
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
        [switch]$UseWQL,

        # Specifies, if the List of drivers should be read.
        # On default, the "Drivers" property will be $null. If enabled, all Drivers will be read into the
        # Drivers property, which can take a considerable amount of time. Especially, if the drivers haven't
        # been processed before.
        [switch]$ReadDrivers,

        # Specifies, if a Task Sequence variable should be created for every Driver Package that was found
        # based on the supplied conditions. The Task Sequence variable will have the ID of the Driver Package
        # as name and a value of 'Install'. This allows to easily create filters inside of a Task Sequence
        # based on the Unique ID of a Driver Package and install it dynamically, without duplicating the
        # filter criterias.
        # It will only work if executed within a Task Sequence.
        [switch]$CreateTSVariables
    )

    begin {
        # Add HardwareIDs and all compatible IDs into a Hashtable to speed up search
        $PnPIDs = @{}
        if ($HardwareIDs.Count -gt 0) {
            $HardwareIDs | Get-CompatibleID | ForEach-Object {$PnPIDs[$_]=$null}
        }

        # Get SCCM/MDT Task Sequence environment
        if ($CreateTSVariables.IsPresent) {
            $TSEnvironment = Get-TSEnvironment
        }
    }

    process {
        $script:Logger.Trace("Get driver package ('Path':'$Path', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')', 'ReadDrivers':'$($ReadDrivers.IsPresent)'  ")

        # Generic logic
        $Root = Get-Item -Path ($Path.TrimEnd('\'))

        if ($Root.PSIsContainer) {
            $script:Logger.Debug('Path supplied. Check if there is a driver package definition file with the same name.')
            if (Test-Path "$($Root.FullName).def") {
                $Root = Get-Item -Path "$($Root.FullName).def"
            }
        } elseif (($Root.Extension -eq '.cab') -or ($Root.Extension -eq '.zip')){
            $script:Logger.Debug('Driver package file supplied. Using driver package definition file name.')
            if (Test-Path ($Root.FullName -replace '.cab', '.txt')) {
                $Root = Get-Item ($Root.FullName -replace '.cab', '.def')
            } elseif (Test-Path ($Root.FullName -replace '.zip', '.def')) {
                $Root = Get-Item ($Root.FullName -replace '.zip', '.def')
            }
        }

        if ($Root.Extension -eq '.def') {
            $script:Logger.Info("Get driver package '$($Root.Name -replace '.def', '')' at '$($Root.Directory.FullName)'.")

            $DefinitionFileName = $Root.FullName
            $InfoFileName = $DefinitionFileName -replace '.def', '.json'

            if (Test-Path -Path ($DefinitionFileName -replace '.def', '.zip')) {
                $DriverPackageFilename = ($DefinitionFileName -replace '.def', '.zip')
            } elseif (Test-Path -Path ($DefinitionFileName -replace '.def', '.cab')) {
                $DriverPackageFilename = ($DefinitionFileName -replace '.def', '.cab')
            } else {
                # No archive found with the Driver Package name.
                # Need to check definition
                #$DriverPackageFilename = [string]::Empty
                $DriverPackageFilename = ($DefinitionFileName -replace '.def', '.zip')
            }

            if (Test-Path $DefinitionFileName) {
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            } else {
                $script:Logger.Warn("No definition file for driver package '$($Root.Name)' found.")

                if (Test-Path -Path ($DefinitionFileName -replace '.def', '.zip')) {
                    New-OSDriverPackageDefinition -DriverPackagePath ($DefinitionFileName -replace '.def', '.zip')
                } elseif (Test-Path -Path ($DefinitionFileName -replace '.def', '.cab')) {
                    New-OSDriverPackageDefinition -DriverPackagePath ($DefinitionFileName -replace '.def', '.cab')
                }

                if (Test-Path $DefinitionFileName) {
                    $script:Logger.Warn("Created stub definition file based on Driver Package file.")
                    $script:Logger.Warn("Please update manually so filters can be applied properly.")
                    $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
                }
            }

            if ($null -ne $Definition) {
                $script:Logger.Debug("Evaluating criteria.")

                $Section = $Definition['OSDriverPackage']
                if ($null -ne $Section) {
                    if ((Compare-Criteria -Section $Section -Filter $OSVersion -Include 'OSVersion') -and
                       (Compare-Criteria -Section $Section -Filter $Architecture -Include 'Architecture') -and
                       (Compare-Criteria -Section $Section -Filter $Tag -Include 'Tag') -and
                       (Compare-Criteria -Section $Section -Filter $Make -Include 'Make') -and
                       (Compare-Criteria -Section $Section -Filter $Model -Include 'Model')
                       ) {

                        $IncludeDriverPackage = $true
                    } else {
                        $IncludeDriverPackage = $false
                    }

                    if ($IncludeDriverPackage -and (-Not([string]::IsNullOrEmpty($Name)))) {
                        $NameFound = $false
                        foreach ($DPName in $Name) {
                            if ((Split-Path -Path $DefinitionFileName -Leaf) -like "$Name") {
                                $NameFound = $true
                            }
                        }

                        $IncludeDriverPackage = $NameFound
                    }

                    # Update Driver Package file name if configured
                    $DPTempName = $Section['DriverPackage']
                    if (-Not([string]::IsNullOrEmpty($DPTempName))) {
                        $DriverPackageFilename = Join-Path -Path (Split-Path -Path $DefinitionFileName -Parent) -ChildPath $DPTempName
                    }

                    # Create default Driver Package name if not found
                    # Might happen when evaluating the definition files only from the exported Driver Packages
                    if ([string]::IsNullOrEmpty($DriverPackageFilename)) {
                        $DriverPackageFilename = ($DefinitionFileName -replace '.def', '.zip')
                    }
                } else {
                    $script:Logger.Warn("Invalid definition file for driver package '$($Root.Name)'. Skipping driver package.")
                    $IncludeDriverPackage = $false
                }

                # Only search for Hardware IDs if Driver Package hasn't been matched yet.
                if (-Not($IncludeDriverPackage)) {
                    if ($PnPIDs.Count -gt 0) {
                        # Get list of Driver Package Hardware IDs from the Definition
                        # Don't use the actual Drivers from the Driver package to allow for customization of filtering.
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
                $IncludeDriverPackage = $false
            }

            if ($IncludeDriverPackage) {
                $script:Logger.Info("Driver package matches the supplied criteria.")

                $DriverPackage = [PSCustomObject]@{
                    DriverPackage = $DriverPackageFilename
                    DefinitionFile = $DefinitionFileName
                    Definition = $Definition
                    DriverArchiveFile = $DriverPackageFilename
                    DriverPath = ($DriverPackageFilename -replace '.zip|.cab', '')
                    Drivers = @()
                }

                # Reading the drivers is a resource intensive task.
                # Only include drivers if explicitly requested.
                if ($ReadDrivers.IsPresent) {
                    # Create Driver Info file if necessary
                    if (-Not(Test-Path $InfoFileName)) {
                        Read-OSDriverPackage -Path $Root
                    }

                    $DriverPackage.Drivers = Get-OSDriver -Path $InfoFileName
                }

                if (($CreateTSVariables.IsPresent) -and ($null -ne $TSEnvironment)) {
                    # Create Task Sequence variable to allow dynamic assignment of Driver Package
                    $DPID = $Definition['OSDriverPackage']['ID']
                    $script:Logger.Info("Adding Driver Package ID '$ID' to list of Task Sequence variables.")
                    $TSEnvironment.Value("$DPID") = 'Install'
                }

                $DriverPackage
            } else {
                $script:Logger.Info("Driver package doesn't match the supplied criteria.")
            }
        } else {
            $script:Logger.Debug("Searching for driver packages in '$Path'.")

            $GetParams = @{
                Path = $Path
                Include = @('*.def')
                Recurse = $true
                File = $true
            }

            if (-Not([string]::IsNullOrEmpty($Name))) {
                $GetParams.Filter = $Name
            }

            $null = $PSBoundParameters.Remove('Path')
            Get-ChildItem @GetParams| Get-OSDriverPackage @PSBoundParameters
        }
    }

}