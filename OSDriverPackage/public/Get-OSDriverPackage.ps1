function Get-OSDriverPackage {
    <#
    .SYNOPSIS
        Gets a Driver Package.

    .DESCRIPTION
        The Get-OSDriverPackage CmdLet get one or multiple Driver Packages based on the supplied conditions.
        All supplied conditions are handled as AND. If no condition is supplied, it is handled as wildcard and
        includeds all.

    .NOTES

    #>
    [CmdletBinding()]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be returned, based on the additional conditions
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
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

        # Filters the Driver Packages by Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Dell*
        [string[]]$Make,

        # Filters the Driver Packages by Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Latitude*
        [string[]]$Model
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
        Write-Verbose "Start getting Driver Package."

        # Generic logic
        $Root = Get-Item -Path $Path
        $DriverPackages = @()

        if ($Root.Extension -eq '.cab') {
            # Single Driver Package
            # TODO: Apply further filtering?
            $Definition = Get-OSDriverPackageDefinition -Filename ($Root.FullName -replace '.cab', '.txt')

            $DriverPackages += [PSCustomObject]@{
                    DriverPackage = ($Root.FullName)
                    DefinitionFile = ($Root.FullName -replace '.cab', '.txt')
                    Definition = $Definition
                }
        } elseif ($Root.Extension -eq '.txt') {
            $Definition = Get-OSDriverPackageDefinition -Filename ($Root.FullName)
            if ($Definition['OSDrivers'].Keys -contains 'Source') {
                $DriverPackage = Join-Path -Path ($Root.Directory.FullName) -ChildPath ($Definition['OSDrivers']['Source'])
                Write-Verbose "  Definition file contains 'Source' key with value '$($Definition['OSDrivers']['Source'])'."
                if (-Not(Test-Path $DriverPackage)) {
                    $DriverPackage = $Root.FullName -replace '.txt', '.cab'
                    Write-Verbose "  Driver Package defined in 'Source' key doesn't exist. Using '$DriverPackage'"
                    if (-Not(Test-Path $DriverPackage)) {
                        $DriverPackageFolder = ($Root.FullName -replace '.txt', '')
                        if (Test-Path $DriverPackageFolder) {
                            Write-Verbose "  Driver Package hasn't been created yet. Creating new Driver Package based on folder '$DriverPackageFolder'."
                            Compress-Folder -FolderPath $DriverPackageFolder -HighCompression
                        }
                    }
                }
            } else {
                $DriverPackage = $Root.FullName -replace '.txt', '.cab'
            }
            if (Test-Path $DriverPackage) {
                $DriverPackages += [PSCustomObject]@{
                    DriverPackage = $DriverPackage
                    DefinitionFile = ($Root.FullName)
                    Definition = $Definition
                }
            } else {
                Write-Verbose "  Driver Package '$DriverPackage' doesn't exist. Skipping file."
            }
        } else {
            # Get initial list of Driver Packages filter by Name
            Get-ChildItem -Path $Path -Include $Name -Recurse -File -Filter '*.txt' | ForEach-Object {
                if (Test-Path $_.FullName) {
                    $Definition = Get-OSDriverPackageDefinition -Filename ($_.FullName)
                    if ($null -ne $Definition) {
                        if ($Definition['OSDrivers'].Keys -contains 'Source') {
                            $DriverPackage = Join-Path -Path ($_.Directory.FullName) -ChildPath ($Definition['OSDrivers']['Source'])
                            Write-Verbose "  Definition file contains 'Source' key with value '$($Definition['OSDrivers']['Source'])'."
                            if (-Not(Test-Path $DriverPackage)) {
                                $DriverPackage = $_.FullName -replace '.cab', '.txt'
                                Write-Verbose "  Driver Package defined in 'Source' key doesn't exist. Using '$DriverPackage'"

                                if (-Not(Test-Path $DriverPackage)) {
                                    $DriverPackageFolder = ($_.FullName -replace '.txt', '')
                                    if (Test-Path $DriverPackageFolder) {
                                        Write-Verbose "  Driver Package hasn't been created yet. Creating new Driver Package based on folder '$DriverPackageFolder'."
                                        Compress-Folder -FolderPath $DriverPackageFolder -HighCompression
                                    }
                                }
                            }
                        } else {
                            $DriverPackage = $_.FullName -replace '.txt', '.cab'
                        }
                        if (Test-Path $DriverPackage) {
                            $DriverPackages += [PSCustomObject]@{
                                DriverPackage = $DriverPackage
                                DefinitionFile = ($_.FullName)
                                Definition = $Definition
                            }
                        } else {
                            Write-Verbose "  Driver Package '$DriverPackage' doesn't exist. Skipping file."
                        }
                    }
                }
            }
        }

        Write-Verbose "Validating Driver Packages against supplied criteria."
        $Result = @()
        foreach ($DriverPackage in $DriverPackages) {
            $DriverPackageName = $DriverPackage.DriverPackage
            Write-Verbose "  Validating '$DriverPackageName'."
            $Definition = $DriverPackage.Definition
            if ($null -eq $Definition) {
                Write-Warning "  Invalid Definition file for Driver Package '$DriverPackageName'. Skipping Driver package."
            } else {
                $Section = $Definition['OSDrivers']
                if (-Not(Compare-Criteria -Section $Section -Filter $OSVersion -Include 'OSVersion' -Exclude 'ExcludeOSVersion')) {
                    $IncludeDriverPackage = $false
                } elseif (-Not(Compare-Criteria -Section $Section -Filter $Tag -Include 'Tag' -Exclude 'ExcludeTag')) {
                    $IncludeDriverPackage = $false
                } elseif (-Not(Compare-Criteria -Section $Section -Filter $Make -Include 'Make' -Exclude 'ExcludeMake')) {
                    $IncludeDriverPackage = $false
                } elseif (-Not(Compare-Criteria -Section $Section -Filter $Model -Include 'Model' -Exclude 'ExcludeModel')) {
                    $IncludeDriverPackage = $false
                } else {
                    $IncludeDriverPackage = $true
                }
            }

            if ($IncludeDriverPackage) {
                $Result += $DriverPackage
            } else {
                Write-Verbose "  Driver Package '$DriverPackageName' doesn't match the supplied criteria."
            }
        }

        Write-Verbose "Finished getting Driver Package."

        $Result
    }
}