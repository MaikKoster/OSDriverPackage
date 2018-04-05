function Copy-OSDriverPackage {
    <#
    .SYNOPSIS
        Copies Driver Packages to a different location.

    .DESCRIPTION

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be returned, based on the additional conditions
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Destination to copy the Driver Packages to
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

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
        # Ensure Target Directory exists
        if (-Not(Test-Path -Path $Destination)) {
            $script:Logger.Info("Creating destination folder '$Destination'.")
            $null = New-Item -Path $Destination -ItemType Directory -Force
        }
    }

    process {
        $script:Logger.Trace("Copy driver package ('Path':'$Path', 'Destination':'$Destination', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')'")

        $DriverPackages = Get-OSDriverPackage -Path $Path -Name $Name -OSVersion $OSVersion -Architecture $Architecture -Tag $Tag -Make $Make -Model $Model
        Foreach ($DriverPackage in $DriverPackages){
            #TODO: Update to use Robocopy. Faster and more reliable
            $DriverPackageName = $DriverPackage.DriverPackage
            $script:Logger.Info("Copying driver package '$DriverPackageName' to '$Destination'.")
            Copy-Item -Path $DriverPackageName -Destination $Destination
            $DefinitionFile = $DriverPackage.DefinitionFile
            if (-Not(Test-Path $DefinitionFile)) {
                $script:Logger.Warn("Definition File '$DefinitionFile' is missing. Creating stub file.")
                New-OSDriverPackageDefinition -DriverPackagePath $DriverPackageName
            }
            $script:Logger.Info("Copying definition file '$DefinitionFile' to '$Destination'.")
            Copy-Item -Path $DefinitionFile -Destination $Destination
        }
    }
}