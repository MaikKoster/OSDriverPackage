function Move-OSDriverPackage {
    <#
    .SYNOPSIS
        Moves Driver Package(s) to a different location.

    .DESCRIPTION

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByObject')]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be returned, based on the additional conditions
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='ByName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Driver Package.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='ByObject')]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$DriverPackage,

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
        [string[]]$Model,

        # Specifies if all related files (Driver Info file, extracted content) should be copied as well
        [switch]$All,

        # Specifies if existing content should be overwritten
        [switch]$Force

    )

    begin {
        # Ensure Target Directory exists
        if (-Not(Test-Path -Path $Destination)) {
            $script:Logger.Info("Creating destination folder '$Destination'.")
            $null = New-Item -Path $Destination -ItemType Directory -Force
        }
    }

    process {
        if ($null -ne $DriverPackage) {
            $script:Logger.Trace("Move driver package ('DriverPackage':'$($DriverPackage.DriverPackage)', 'Destination':'$Destination', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')', 'All':'$All'")
            $DriverPackages = ,$DriverPackage
        } else {
            $script:Logger.Trace("Move driver package ('Path':'$Path', 'Destination':'$Destination', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')', 'All':'$All'")
            $DriverPackages = Get-OSDriverPackage -Path $Path -Name $Name -OSVersion $OSVersion -Architecture $Architecture -Tag $Tag -Make $Make -Model $Model
        }

        Foreach ($DrvPkg in $DriverPackages){
            if ((Split-Path -Path $DrvPkg.DriverPackage -Parent) -ne $Destination) {
                $MoveArgs = @{
                    Destination = $Destination
                    Force = $Force.IsPresent
                }

                # Archive
                $DriverPackageName = $DrvPkg.DriverPackage
                $script:Logger.Info("Moving driver package '$DriverPackageName' to '$Destination'.")
                Move-Item @MoveArgs -Path $DriverPackageName

                # Definition File
                $DefinitionFile = $DrvPkg.DefinitionFile
                if (-Not(Test-Path $DefinitionFile)) {
                    $script:Logger.Warn("Definition File '$DefinitionFile' is missing. Creating stub file.")
                    New-OSDriverPackageDefinition -DriverPackagePath $DriverPackageName
                }
                $script:Logger.Info("Moving definition file '$DefinitionFile' to '$Destination'.")
                Move-Item @MoveArgs -Path $DefinitionFile

                if ($All.IsPresent) {
                    # Info File
                    $InfoFile = ($DrvPkg.DriverPackage -replace '.cab|.zip|.txt', '.json')
                    $script:Logger.Info("Copying driver info file '$InfoFile' to '$Destination'.")
                    Move-Item @MoveArgs -Path $InfoFile

                    # Archive content
                    $ExpandedContent = ($DrvPkg.DriverPackage -replace '.cab|.zip|.txt', '')
                    if (Test-Path -Path $ExpandedContent) {
                        $script:Logger.Info("Copying Driver contentfrom '$ExpandedContent' to '$Destination'.")
                        Move-Item @MoveArgs -Path $ExpandedContent
                    }
                }
            } else {
                $Script:Logger.Warn("Source path '$($DrvPkg.DriverPackage)' is the same as the destination path '$Destination'. Skipping move operation.")
            }
        }
    }
}