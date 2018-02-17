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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
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
        [string[]]$Model
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start getting Driver Package."
    }

    process {
        Write-Verbose "  Processing path '$Path'."

        # Generic logic
        $Root = Get-Item -Path $Path
        $DriverPackages = @()

        if ($Root.Extension -eq '.txt'){
            $Root = Get-Item ($Root.FullName -replace '.txt', '.cab')
        }

        if ($Root.Extension -eq '.cab') {
            Write-Verbose " Processing Driver Package '$($Root.Fullname)'"

            $DefinitionFileName = $Root.FullName -replace '.cab', '.txt'
            $InfoFileName = $Root.FullName -replace '.cab', '.json'

            if (Test-Path $DefinitionFileName) {
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            } else {
                Write-Warning "  No Definition file for Driver Package '$DriverPackageName' found. Creating stub."
                Write-Warning "  Please update manually so filters can be applied properly."
                New-OSDriverPackageDefinition -DriverPackagePath $Root.FullName
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            }

            Write-Verbose "  Evaluating criteria."

            if ($null -eq $Definition) {
                Write-Warning "    Invalid Definition file for Driver Package '$DriverPackageName'. Skipping Driver package."
            } else {
                $Section = $Definition['OSDrivers']
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
            }

            if ($IncludeDriverPackage) {
                Write-Verbose "  Driver Package matches the supplied criteria."
                # Create Driver Info file if necessary
                if (-Not(Test-Path $InfoFileName)) {
                    Read-OSDriverPackage -Path $Root
                }

                #$DriverPackages += [PSCustomObject]@{
                [PSCustomObject]@{
                    DriverPackage = ($Root.FullName)
                    DefinitionFile = ($Root.FullName -replace '.cab', '.txt')
                    Definition = $Definition
                    Drivers = (Get-OSDriver -Path $InfoFileName)
                }
            } else {
                Write-Verbose "  Driver Package doesn't match the supplied criteria."
            }

        # } elseif ($Root.Extension -eq '.txt') {
        #     $Definition = Get-OSDriverPackageDefinition -Path ($Root.FullName)
        #     if ($Definition['OSDrivers'].Keys -contains 'Source') {
        #         $DriverPackage = Join-Path -Path ($Root.Directory.FullName) -ChildPath ($Definition['OSDrivers']['Source'])
        #         Write-Verbose "    Definition file contains 'Source' key with value '$($Definition['OSDrivers']['Source'])'."
        #         if (-Not(Test-Path $DriverPackage)) {
        #             $DriverPackage = $Root.FullName -replace '.txt', '.cab'
        #             Write-Verbose "    Driver Package defined in 'Source' key doesn't exist. Using '$DriverPackage'"
        #             if (-Not(Test-Path $DriverPackage)) {
        #                 $DriverPackageFolder = ($Root.FullName -replace '.txt', '')
        #                 if (Test-Path $DriverPackageFolder) {
        #                     Write-Verbose "    Driver Package hasn't been created yet. Creating new Driver Package based on folder '$DriverPackageFolder'."
        #                     Compress-Folder -FolderPath $DriverPackageFolder -HighCompression
        #                 }
        #             }
        #         }
        #     } else {
        #         $DriverPackage = $Root.FullName -replace '.txt', '.cab'
        #     }
        #     if (Test-Path $DriverPackage) {
        #         $DriverPackages += [PSCustomObject]@{
        #             DriverPackage = $DriverPackage
        #             DefinitionFile = ($Root.FullName)
        #             Definition = $Definition
        #         }
        #     } else {
        #         Write-Verbose "    Driver Package '$DriverPackage' doesn't exist. Skipping file."
        #     }
        } else {
            Get-ChildItem -Path $Path -Include $Name -Recurse -File -Filter '*.cab' | Get-OSDriverPackage

            # # Get initial list of Driver Packages filter by Name
            # Get-ChildItem -Path $Path -Include $Name -Recurse -File -Filter '*.txt' | ForEach-Object {
            #     if (Test-Path $_.FullName) {
            #         $Definition = Get-OSDriverPackageDefinition -Path ($_.FullName)
            #         if ($null -ne $Definition) {
            #             if ($Definition['OSDrivers'].Keys -contains 'Source') {
            #                 $DriverPackage = Join-Path -Path ($_.Directory.FullName) -ChildPath ($Definition['OSDrivers']['Source'])
            #                 Write-Verbose "    Definition file contains 'Source' key with value '$($Definition['OSDrivers']['Source'])'."
            #                 if (-Not(Test-Path $DriverPackage)) {
            #                     $DriverPackage = $_.FullName -replace '.cab', '.txt'
            #                     Write-Verbose "    Driver Package defined in 'Source' key doesn't exist. Using '$DriverPackage'"

            #                     if (-Not(Test-Path $DriverPackage)) {
            #                         $DriverPackageFolder = ($_.FullName -replace '.txt', '')
            #                         if (Test-Path $DriverPackageFolder) {
            #                             Write-Verbose "    Driver Package hasn't been created yet. Creating new Driver Package based on folder '$DriverPackageFolder'."
            #                             Compress-Folder -FolderPath $DriverPackageFolder -HighCompression
            #                         }
            #                     }
            #                 }
            #             } else {
            #                 $DriverPackage = $_.FullName -replace '.txt', '.cab'
            #             }
            #             if (Test-Path $DriverPackage) {
            #                 $DriverPackages += [PSCustomObject]@{
            #                     DriverPackage = $DriverPackage
            #                     DefinitionFile = ($_.FullName)
            #                     Definition = $Definition
            #                 }
            #             } else {
            #                 Write-Verbose "    Driver Package '$DriverPackage' doesn't exist. Skipping file."
            #             }
            #         }
            #     }
            #}
        }

        # Write-Verbose "  Validating Driver Packages against supplied criteria."
        # $Result = @()
        # foreach ($DriverPackage in $DriverPackages) {
        #     $DriverPackageName = $DriverPackage.DriverPackage
        #     Write-Verbose "    Validating '$DriverPackageName'."
        #     $Definition = $DriverPackage.Definition
        #     if ($null -eq $Definition) {
        #         Write-Warning "    Invalid Definition file for Driver Package '$DriverPackageName'. Skipping Driver package."
        #     } else {
        #         $Section = $Definition['OSDrivers']
        #         if (-Not(Compare-Criteria -Section $Section -Filter $OSVersion -Include 'OSVersion')) {
        #             $IncludeDriverPackage = $false
        #         } elseif (-Not(Compare-Criteria -Section $Section -Filter $Tag -Include 'Architecture')) {
        #             $IncludeDriverPackage = $false
        #         } elseif (-Not(Compare-Criteria -Section $Section -Filter $Tag -Include 'Tag')) {
        #             $IncludeDriverPackage = $false
        #         } elseif (-Not(Compare-Criteria -Section $Section -Filter $Make -Include 'Make')) {
        #             $IncludeDriverPackage = $false
        #         } elseif (-Not(Compare-Criteria -Section $Section -Filter $Model -Include 'Model')) {
        #             $IncludeDriverPackage = $false
        #         } else {
        #             $IncludeDriverPackage = $true
        #         }
        #     }

        #     if ($IncludeDriverPackage) {
        #         $Result += $DriverPackage
        #     } else {
        #         Write-Verbose "  Driver Package '$DriverPackageName' doesn't match the supplied criteria."
        #     }
        # }

        # $Result
    }
    end{
        Write-Verbose "Finished getting Driver Package."
    }
}