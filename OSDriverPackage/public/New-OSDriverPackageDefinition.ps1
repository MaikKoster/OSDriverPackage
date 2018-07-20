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
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ParameterSetName='PackageWithSettings')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("Path")]
        [string]$DriverPackagePath,

        # Specifies the name and path of the Driver Package Definition file
        [Parameter(ParameterSetName='PackageWithSettings')]
        [Parameter(Mandatory, ParameterSetName='NameWithSettings')]
        [Parameter(Mandatory, ParameterSetName='NameWithDefinition')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # Specifies generic tag(s) that can be used to further identify the Driver Package.
        # Can be used to e.g. identify specific Core Packages.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Tag = '*',

        # Specifies the excluded generic tag(s).
        # Can be used to e.g. identify specific Core Packages.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeTag,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$OSVersion = '*',

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeOSVersion,

        # Specifies the supported Architectures.
        # Recommended to use the tags x86, x64 and/or ia64.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Architecture = '*',

        # Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Make = '*',

        # Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$ExcludeMake,

        # Specifies the supported Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$Model  = '*',

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
        [Parameter(ParameterSetName='PackageWithSettings')]
        [string[]]$WQL,

        # Specifies the list PNP IDs from the Driver Package.
        [Parameter(ParameterSetName='NameWithSettings')]
        [Parameter(ParameterSetName='PackageWithSettings')]
        [hashtable]$PNPIDs,

        # Specifies the Driver Package Definition
        [Parameter(Mandatory, ParameterSetName='NameWithDefinition')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Definition,

        # Specifies if an existing Driver Package Definition file should be overwritten.
        [switch]$Force,

        # Specifies if the name and path to the new Driver Package Definition file should be returned.
        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'PackageWithSettings'){
            $script:Logger.Trace("New driver package definition ('DriverPackagePath':'$DriverPackagePath', 'Name':'$Name', Tag':'$($Tag -join ',')', 'ExcludeTag':'$($ExcludeTag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'ExcludeOSVersion':'$($ExcludeOSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'ExcludeMake':'$($ExcludeMake -join ',')', 'Model':'$($Model -join ',')', 'ExcludeModel':'$($ExcludeModel -join ',')', 'URL':'$URL', 'Force':'$Force', 'PassThru':'$PassThru'")
        } elseif ($PSCmdlet.ParameterSetName -eq 'NameWithSettings') {
            $script:Logger.Trace("New driver package definition ('Name':'$Name', Tag':'$($Tag -join ',')', 'ExcludeTag':'$($ExcludeTag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'ExcludeOSVersion':'$($ExcludeOSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'ExcludeMake':'$($ExcludeMake -join ',')', 'Model':'$($Model -join ',')', 'ExcludeModel':'$($ExcludeModel -join ',')', 'URL':'$URL', 'Force':'$Force', 'PassThru':'$PassThru'")
        } elseif ($PSCmdlet.ParameterSetName -eq 'NameWithDefinition') {
            $script:Logger.Trace("New driver package definition ('Name':'$Name', 'Definition':'$($Definition | ConvertTo-Json)', 'Force':'$Force', 'PassThru':'$PassThru'")
        }

        if ([string]::IsNullOrEmpty($DriverPackagePath)) {
            $FileName = $Name
        } else {
            $DriverPackage = Get-Item $DriverPackagePath

            if ([string]::IsNullOrEmpty($Name)) {
                if ($DriverPackage.Extension -eq 'txt') {
                    $FileName = $DriverPackage
                }elseif (($DriverPackage.Extension -eq '.cab') -or ($DriverPackage.Extension -eq '.zip')) {
                    $FileName = "$($DriverPackage.FullName -replace "$($DriverPackage.Extension)", '').txt"
                } else {
                    $FileName = "$($DriverPackage.FullName).txt"
                }
            } else {
                $FileName = Join-Path -Path ($DriverPackage.Parent.FullName) -ChildPath "$($Name -replace '.txt' ,'') .txt"
            }
        }

        $script:Logger.Info("Creating new Driver Package Definition file '$Filename'.")

        if ($null -eq $Definition) {

            $NewDefinition = [System.Collections.Specialized.OrderedDictionary]@{}

            # Section OSDriver must be present
            $script:Logger.Debug("Creating OSDrivers section")
            $NewDefinition['OSDrivers'] = [System.Collections.Specialized.OrderedDictionary]@{}

            # every definition must have a unique ID, that is used to properly identify and sync exported Driver Packages
            $NewDefinition['OSDrivers']['ID'] = [guid]::NewGuid().ToString()
            $script:Logger.Debug("ID = $($NewDefinition['OSDrivers']['ID'])")

            if ($null -ne $Tag) {
                $NewDefinition['OSDrivers']['Tag'] = $Tag -join ', '
                $script:Logger.Debug("Tag = $($NewDefinition['OSDrivers']['Tag'])")
            } else {
                $NewDefinition['OSDrivers']['Tag'] = ''
            }

            if ($null -ne $ExcludeTag) {
                $NewDefinition['OSDrivers']['ExcludeTag'] = $Tag -join ', '
                $script:Logger.Debug("ExcludeTag = $($NewDefinition['OSDrivers']['ExcludeTag'])")
            } else {
                #$NewDefinition['OSDrivers']['Tag'] = ''
            }

            if ($null -ne $OSVersion) {
                $NewDefinition['OSDrivers']['OSVersion'] = $OSVersion -join ', '
                $script:Logger.Debug("OSVersion = $($NewDefinition['OSDrivers']['OSVersion'])")
            } else {
                #$NewDefinition['OSDrivers']['OSVersion'] = ''
            }

            if ($null -ne $ExcludeOSVersion) {
                $NewDefinition['OSDrivers']['ExcludeOSVersion'] = $ExcludeOSVersion -join ', '
                $script:Logger.Debug("ExcludeOSVersion = $($NewDefinition['OSDrivers']['ExcludeOSVersion'])")
            } else {
                #$NewDefinition['OSDrivers']['ExcludeOSVersion'] = ''
            }

            if ($null -ne $Architecture) {
                $NewDefinition['OSDrivers']['Architecture'] = $Architecture -join ', '
                $script:Logger.Debug("Architecture = $($NewDefinition['OSDrivers']['Architecture'])")
            } else {
                #$NewDefinition['OSDrivers']['Architecture'] = ''
            }

            if ($null -ne $Make) {
                $NewDefinition['OSDrivers']['Make'] = $Make -join ', '
                $script:Logger.Debug("Make = $($NewDefinition['OSDrivers']['Make'])")
            } else {
                #$NewDefinition['OSDrivers']['Make'] = ''
            }

            if ($null -ne $ExcludeMake) {
                $NewDefinition['OSDrivers']['ExcludeMake'] = $ExcludeMake -join ', '
                $script:Logger.Debug("ExcludeMake = $($NewDefinition['OSDrivers']['ExcludeMake'])")
            } else {
                #$NewDefinition['OSDrivers']['ExcludeMake'] = ''
            }

            if ($null -ne $Model) {
                $NewDefinition['OSDrivers']['Model'] = $Model -join ', '
                $script:Logger.Debug("Model = $($NewDefinition['OSDrivers']['Model'])")
            }else {
                #$NewDefinition['OSDrivers']['Model'] = ''
            }

            if ($null -ne $ExcludeModel) {
                $NewDefinition['OSDrivers']['ExcludeModel'] = $ExcludeModel -join ', '
                $script:Logger.Debug("ExcludeModel = $($NewDefinition['OSDrivers']['ExcludeModel'])")
            }else {
                #$NewDefinition['OSDrivers']['ExcludeModel'] = ''
            }

            if (-Not([string]::IsNullOrEmpty($URL))) {
                $NewDefinition['OSDrivers']['URL'] = $URL -join ', '
                $script:Logger.Debug("URL = $($NewDefinition['OSDrivers']['URL'])")
            }else {
                #$NewDefinition['OSDrivers']['URL'] = ''
            }

            # WQL
            if ($null -ne $WQL) {
                $script:Logger.Debug("Creating WQL section.")
                $NewDefinition['WQL'] = [System.Collections.Specialized.OrderedDictionary]@{}
                foreach ($query in $WQL) {
                    $WQLCount++
                    $NewDefinition['WQL']["Comment_$WQLCount"] = $query
                    $script:Logger.Debug("$Query")
                }
            }

            # Plug-And-Play IDs
            if ($null -ne $PNPIDs) {
                $script:Logger.Debug("Creating PNPIDS section.")
                $NewDefinition['PNPIDS'] = [System.Collections.Specialized.OrderedDictionary]@{}
                foreach ($PNPID in $PNPIDs.Keys) {
                    $NewDefinition['PNPIDS']["$PNPID"] = $PNPIDs[$PNPID]
                    $script:Logger.Debug("$PNPID = $($PNPIDs[$PNPID])")
                }
            }
        } else {
            $script:Logger.Debug("Using supplied definition.")
            $NewDefinition = $Definition
        }

        if (-Not(Test-Path $FileName) ) {
            if ($PSCmdlet.ShouldProcess("Saving driver package definition file '$FileName'.")) {
                $script:Logger.Debug("Saving driver package definition file '$FileName'.")
                Write-DefinitionFile -Definition $NewDefinition -Path $FileName
            }
        } elseif ((Test-Path $FileName) -and ($Force.IsPresent)) {
            if ($PSCmdlet.ShouldProcess("Overwriting existing driver package definition file '$FileName'.")) {
                $script:Logger.Debug("Overwriting existing driver package definition file '$FileName'.")
                Write-DefinitionFile -Definition $NewDefinition -Path $FileName
            }
        } else {
            $script:Logger.Error("Driver package definition file '$Filename' exists and '-Force' is not specified.")
            throw "Driver package definition file '$Filename' exists and '-Force' is not specified."
        }

        if ($PassThru.IsPresent) {
            $FileName
        }
    }
}