function New-ExportDefinition {
    <#
    .SYNOPSIS
        Creates a new Export Definition

    .DESCRIPTION

    .NOTES

    #>

    param(
        # Specifies the name of the Export definition
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # Specifies the root of the Driver package source
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path')]
        [string]$SourceRoot,

        # Specifies the root of the Driver Package export path
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetRoot,

        [string]$Description,

        # Filters the Driver Packages by Name
        # Wildcards are allowed e.g. Intel*
        [string[]]$DriverPackageName,

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
        $ExportDefinitionFilename = 'DriverPackageExports.json'
        $ExportDefinitionFullname = Join-Path -Path $SourceRoot -ChildPath $ExportDefinitionFilename
    }

    process {
        $script:Logger.Trace("New export definition ('Name':'$Name', 'SourceRoot':'$SourceRoot', 'TargetRoot':'$TargetRoot'), 'DriverPackageName':'$($DriverPackageName -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')'")

        $ExportDefinition = Get-ExportDefinition -Path $SourceRoot -Name $Name

        if ($null -eq $ExportDefinition) {
            $NewDefinition = [PSCustomObject]@{
                Id = [guid]::NewGuid().ToString()
                Name = $Name
                SourceRoot = $SourceRoot
                TargetRoot = $TargetRoot
                Description = $Description
                DriverPackages = @()
                DriverPackageName = $DriverPackageName
                Tag = $Tag
                OSVersion = $OSVersion
                Architecture = $Architecture
                Make = $Make
                Model = $Model
            }

            Write-ExportDefinitionFile -Path $ExportDefinitionFullname -Definitions $NewDefinition

            $NewDefinition
        } else {
            $script:Logger.Error("Driver package export definition '$Name' already exists.")
            throw "Driver package export definition '$Name' already exists."
        }
    }
}