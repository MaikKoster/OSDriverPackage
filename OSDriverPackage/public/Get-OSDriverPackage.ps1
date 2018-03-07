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
        $Root = Get-Item -Path ($Path.Trim("\"))

        if ($Root.PSIsContainer) {
            if (Test-Path "$($Root.FullName).cab") {
                $Root = Get-Item -Path "$($Root.FullName).cab"
            } elseif (Test-Path "$($Root.FullName).zip") {
                $Root = Get-Item -Path "$($Root.FullName).zip"
            }
        }

        if ($Root.Extension -eq '.txt'){
            if (Test-Path ($Root.FullName -replace '.txt', '.cab')) {
                $Root = Get-Item ($Root.FullName -replace '.txt', '.cab')
            } elseif (Test-Path ($Root.FullName -replace '.txt', '.zip')) {
                $Root = Get-Item ($Root.FullName -replace '.txt', '.zip')
            }
        }

        if (($Root.Extension -eq '.zip') -or ($Root.Extension -eq '.cab')) {
            Write-Verbose " Processing Driver Package '$($Root.Fullname)'"

            $DefinitionFileName = $Root.FullName -replace "$($Root.Extension)", '.txt'
            $InfoFileName = $Root.FullName -replace "$($Root.Extension)", '.json'

            if (Test-Path $DefinitionFileName) {
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            } else {
                Write-Warning "  No Definition file for Driver Package '$($Root.Name)' found. Creating stub."
                Write-Warning "  Please update manually so filters can be applied properly."
                New-OSDriverPackageDefinition -DriverPackagePath $Root.FullName
                $Definition = Get-OSDriverPackageDefinition -Path ($DefinitionFileName)
            }

            Write-Verbose "  Evaluating criteria."

            if ($null -eq $Definition) {
                Write-Warning "    Invalid Definition file for Driver Package '$($Root.Name)'. Skipping Driver package."
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

                [PSCustomObject]@{
                    DriverPackage = ($Root.FullName)
                    DefinitionFile = $DefinitionFileName
                    Definition = $Definition
                    Drivers = (Get-OSDriver -Path $InfoFileName)
                }
            } else {
                Write-Verbose "  Driver Package doesn't match the supplied criteria."
            }
        } else {
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

    end{
        Write-Verbose "Finished getting Driver Package."
    }
}