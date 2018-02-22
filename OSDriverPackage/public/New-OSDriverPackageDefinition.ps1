function New-OSDriverPackageDefinition {
    <#
    .SYNOPSIS
        Creates a new Driver Package definition file.

    .DESCRIPTION
        Creates a new Driver Package definition file.

    .NOTES

    #>
    [OutputType([string])]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='PackageWithSettings')]
    param (
        # Specifies the name and path of the Driver Package
        # The Definition File will be named exactly the same as the Driver Package.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='PackageWithSettings')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("Path")]
        [string]$DriverPackagePath,

        # Specifies the name and path of the Driver Package Definition file
        [Parameter(Mandatory, ParameterSetName='NameWithSettings')]
        [Parameter(Mandatory, ParameterSetName='NameWithDefinition')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$OSVersion,

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeOSVersion,

        # Specifies the supported Architectures.
        # Recommended to use the tags x86, x64 and/or ia64.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Architecture,

        # Specifies generic tag(s) that can be used to further identify the Driver Package.
        # Can be used to e.g. identify specific Core Packages.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Tag,

        # Specifies the excluded generic tag(s).
        # Can be used to e.g. identify specific Core Packages.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeTag,

        # Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Make,

        # Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeMake,

        # Specifies the supported Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Model,

        # Specifies the excluded Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeModel,

        # Specifies the URL for the Driver Package content.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string]$URL,

        # Specifies a list of WQL commands that can be used to match devices for this Driver Package.
        [Parameter(ParameterSetName='NameWithSettings')]
        [string[]]$WQL,

        # Specifies the list PNP IDs from the Driver Package.
        [Parameter(ParameterSetName='NameWithSettings')]
        [hashtable]$PNPIDs,

        # Specifies the Driver Package Definition
        [Parameter(Mandatory, ParameterSetName='NameWithDefinition')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Definition,

        #Specifies, if the PnP IDs shouldn't be extracted from the Driver Package
        [Parameter(ParameterSetName='PackageWithSettings')]
        [switch]$SkipPNPDetection,

        # Specifies if an existing Driver Package Definition file should be overwritten.
        [switch]$Force,

        # Specifies if the name and path to the new Drive Package Definition file should be returned.
        [switch]$PassThru
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    process {
        if ([string]::IsNullOrEmpty($FileName)) {
            $DriverPackage = Get-Item $DriverPackagePath
            if (($DriverPackage.Extension -eq 'cab') -or ($DriverPackage.Extension -eq 'zip')) {
                $FileName = "$($DriverPackage.FullName -replace "$($DriverPackage.Extension)", '').txt"
            }
        }
        Write-Verbose "Start creating new Driver Package Definition file '$Filename'."

        if ($null -eq $Definition) {

            $NewDefinition = [System.Collections.Specialized.OrderedDictionary]@{}

            # Section OSDriver must be present
            Write-Verbose "  Creating OSDrivers section"
            $NewDefinition['OSDrivers'] = [System.Collections.Specialized.OrderedDictionary]@{}
            if ($null -ne $OSVersion) {
                $NewDefinition['OSDrivers']['OSVersion'] = $OSVersion -join ', '
                Write-Verbose "    OSVersion = $($NewDefinition['OSDrivers']['OSVersion'])"
            } else {
                $NewDefinition['OSDrivers']['OSVersion'] = ''
            }

            if ($null -ne $ExcludeOSVersion) {
                $NewDefinition['OSDrivers']['ExcludeOSVersion'] = $ExcludeOSVersion -join ', '
                Write-Verbose "    ExcludeOSVersion = $($NewDefinition['OSDrivers']['ExcludeOSVersion'])"
            } else {
                $NewDefinition['OSDrivers']['ExcludeOSVersion'] = ''
            }

            if ($null -ne $Architecture) {
                $NewDefinition['OSDrivers']['Architecture'] = $Architecture -join ', '
                Write-Verbose "    Architecture = $($NewDefinition['OSDrivers']['Architecture'])"
            } else {
                $NewDefinition['OSDrivers']['Architecture'] = ''
            }

            if ($null -ne $Architecture) {
                $NewDefinition['OSDrivers']['Tag'] = $Tag -join ', '
                Write-Verbose "    Tag = $($NewDefinition['OSDrivers']['Tag'])"
            } else {
                $NewDefinition['OSDrivers']['Tag'] = ''
            }


            if ($null -ne $Make) {
                $NewDefinition['OSDrivers']['Make'] = $Make -join ', '
                Write-Verbose "    Make = $($NewDefinition['OSDrivers']['Make'])"
            } else {
                $NewDefinition['OSDrivers']['Make'] = ''
            }

            if ($null -ne $ExcludeMake) {
                $NewDefinition['OSDrivers']['ExcludeMake'] = $ExcludeMake -join ', '
                Write-Verbose "    ExcludeMake = $($NewDefinition['OSDrivers']['ExcludeMake'])"
            } else {
                $NewDefinition['OSDrivers']['ExcludeMake'] = ''
            }

            if ($null -ne $Model) {
                $NewDefinition['OSDrivers']['Model'] = $Model -join ', '
                Write-Verbose "    Model = $($NewDefinition['OSDrivers']['Model'])"
            }else {
                $NewDefinition['OSDrivers']['Model'] = ''
            }

            if ($null -ne $ExcludeModel) {
                $NewDefinition['OSDrivers']['ExcludeModel'] = $ExcludeModel -join ', '
                Write-Verbose "    ExcludeModel = $($NewDefinition['OSDrivers']['ExcludeModel'])"
            }else {
                $NewDefinition['OSDrivers']['ExcludeModel'] = ''
            }

            if (-Not([string]::IsNullOrEmpty($URL))) {
                $NewDefinition['OSDrivers']['URL'] = $URL -join ', '
                Write-Verbose "    URL = $($NewDefinition['OSDrivers']['URL'])"
            }else {
                $NewDefinition['OSDrivers']['URL'] = ''
            }

            if ($PSCmdlet.ParameterSetName -eq 'PackageWithSettings') {
                if ($SkipPNPDetection.IsPresent) {
                    Write-Verbose "  Skipping evluation of Driver files."
                } else {
                    Write-Verbose "  Creating WQL and PNPIDS sections."
                    # TODO: Check if Folder or cab file. Expand and compress on the fly

                    # Get all Driver infos and put into hashtable
                    Write-Verbose "  Searching for drivers."
                    $InfoFilePath = $FileName -replace '.txt', '.json'

                    # Ensure PackageInfo file exists
                    if (-Not(Test-Path -Path $InfoFilePath)) {
                        Read-OSDriverPackage -Path $DriverPackagePath
                    }

                    $NewDefinition['WQL'] = [System.Collections.Specialized.OrderedDictionary]@{}
                    $NewDefinition['PNPIDS'] = [System.Collections.Specialized.OrderedDictionary]@{}
                    $Drivers = Get-OSDriver -Path ($InfoFilePath)
                    $Drivers | Select-Object -ExpandProperty HardwareIDs |
                        Select-Object -Property HardwareID,HardwareDescription -Unique |
                        Sort-Object -Property HardwareID | ForEach-Object {
                            $Count++
                            $HardwareID = $_.HardwareID
                            if (-Not([string]::IsNullOrEmpty($HardwareID))) {
                                $NewDefinition['WQL']["Comment_$Count"] = "Select * FROM Win32_PnPEntity WHERE DeviceID LIKE '$HardwareID'"
                                $NewDefinition['PNPIDS']["$HardwareID"] = $_.HardwareDescription
                                Write-Verbose "    $HardwareID = $($_.HardwareDescription)"
                            }
                        }

                }
            } else {
                # WQL
                if ($null -ne $WQL) {
                    Write-Verbose "  Creating WQL section."
                    $NewDefinition['WQL'] = [System.Collections.Specialized.OrderedDictionary]@{}
                    foreach ($query in $WQL) {
                        $WQLCount++
                        $NewDefinition['WQL']["Comment_$WQLCount"] = $query
                        Write-Verbose "$Query"
                    }
                }

                # Plug-And-Play IDs
                if ($null -ne $PNPIDs) {
                    Write-Verbose "  Creating PNPIDS section."
                    $NewDefinition['PNPIDS'] = [System.Collections.Specialized.OrderedDictionary]@{}
                    foreach ($PNPID in $PNPIDs.Keys) {
                        $NewDefinition['PNPIDS']["$PNPID"] = $PNPIDs[$PNPID]
                        Write-Verbose "$PNPID = $($PNPIDs[$PNPID])"
                    }
                }
            }
        } else {
            Write-Verbose "  Using supplied Definition."
            $NewDefinition = $Definition
        }

        if (-Not(Test-Path $FileName) ) {
            if ($PSCmdlet.ShouldProcess("Saving driver package definition file '$FileName'.")) {
                Write-Verbose "  Saving Driver Package Definition file '$FileName'."
                Write-DefinitionFile -Definition $NewDefinition -Path $FileName
            }
        } elseif ((Test-Path $FileName) -and ($Force.IsPresent)) {
            if ($PSCmdlet.ShouldProcess("Overwriting existing driver package definition file '$FileName'.")) {
                Write-Verbose "  Overwriting existing Driver Package Definition file '$FileName'."
                Write-DefinitionFile -Definition $NewDefinition -Path $FileName
            }
        } else {
            throw "Driver Package Definition File '$Filename' exists and '-Force' is not specified."
        }

        if ($PassThru.IsPresent) {
            $FileName
        }

        Write-Verbose "Finished creating new Driver Package Definition file."
    }
}