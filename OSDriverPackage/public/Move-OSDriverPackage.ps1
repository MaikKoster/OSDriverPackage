function Move-OSDriverPackage {
    <#
    .SYNOPSIS
        Moves Driver Package(s) to a different location.

    .DESCRIPTION

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByDriverPackage')]
    param (
        # Specifies the Driver Package, that should be moved.
        [Parameter(Mandatory, ParameterSetName='ByDriverPackage', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$DriverPackage,

        # Specifies the name and path of Driver Package that should be moved.
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((Test-Path $_) -and ($_ -like '*.def'))})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Destination to move the Driver Packages to
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        # Specifies if any existing file should be overwritten
        [switch]$Force,

        # Specifies if only OSD related content (Driver Definition file and Archive) should be moved
        [switch]$OSD,

        # Specifies, if the updated Driver Package should be returned.
        [switch]$Passthru

    )

    begin {
        # Ensure Target Directory exists
        if (-Not(Test-Path -Path $Destination)) {
            $script:Logger.Info("Creating destination folder '$Destination'.")
            $null = New-Item -Path $Destination -ItemType Directory -Force
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            $script:Logger.Trace("Move driver package ('Path':'$Path', 'Destination':'$Destination', 'Force':'$Force', 'OSD':'$OSD', 'Passthru':'$Passthru'")
        } else {
            $script:Logger.Trace("Move driver package ('DriverPackage':'$($DriverPackage.DefinitionFile)', 'Destination':'$Destination', 'Force':'$Force', 'OSD':'$OSD', 'Passthru':'$Passthru'")
        }

        # Get Driver Package
        if ($null -eq $DriverPackage) {
            $DriverPackage = Get-OSDriverPackage -Path $Path
        }

        # Ensure Driver package is valid
        if (Test-OSDriverPackage -DriverPackage $DriverPackage) {
            $script:Logger.Info("Moving driver package '$($DriverPackage.DefinitionFile)' to '$Destination'.")

            if ((Split-Path -Path $DriverPackage.DefinitionFile -Parent) -ne $Destination) {
                $MoveArgs = @{
                    Destination = $Destination
                    Force = $Force.IsPresent
                }

                # Move Definition File
                $DefinitionFile = $DriverPackage.DefinitionFile
                if (-Not(Test-Path $DefinitionFile)) {
                    $script:Logger.Warn("Definition File '$DefinitionFile' is missing. Creating stub file.")
                    New-OSDriverPackageDefinition -DriverPackagePath $DriverPackageName
                }
                $script:Logger.Debug("Moving driver package definition file '$DefinitionFile' to '$Destination'.")
                Move-Item @MoveArgs -Path $DefinitionFile

                # Move Archive if it exists
                $DriverAchiveFile = $DriverPackage.DriverArchiveFile
                if (Test-Path -Path $DriverAchiveFile) {
                    $script:Logger.Debug("Moving driver archive file '$DriverAchiveFile' to '$Destination'.")
                    Move-Item @MoveArgs -Path $DriverAchiveFile
                } else {
                    $script:Logger.Debug("Driver archive file '$DriverAchiveFile' is not present. Skipping move operation.")
                }

                if ($OSD.IsPresent) {
                    $script:Logger.Debug("Skipping move operation for drivers and driver info file.")
                } else {
                    # Move Driver Info File
                    $InfoFile = $DriverPackage.DriverInfoFile
                    if (Test-Path -Path $InfoFile) {
                        $script:Logger.Debug("Moving driver info file '$InfoFile' to '$Destination'.")
                        Move-Item @MoveArgs -Path $InfoFile
                    } else {
                        $script:Logger.Debug("Driver info file '$InfoFile' is not present. Skipping move operation.")
                    }

                    # Move Drivers
                    $DriverPath = $DriverPackage.DriverPath
                    if (Test-Path -Path $DriverPath) {
                        $script:Logger.Debug("Copying Drivers from '$DriverPath' to '$Destination'.")
                        Move-Item @MoveArgs -Path $DriverPath
                    } else {
                        $script:Logger.Debug("Drivers at '$DriverAchiveFile' are not present. Skipping move operation.")
                    }
                }
            } else {
                $Script:Logger.Warn("Source path '$($DriverPackage.DefinitionFile)' is the same as the destination path '$Destination'. Skipping move operation.")
            }

        } else {
            $script:logger.Error("Driver Package '$($DriverPackage.DefinitionFile)' is not valid. Skipping move operation.")
        }

        if ($Passthru.IsPresent) {
            Get-OSDriverPackage -Path (Join-Path -Path $Destination -ChildPath (Split-Path -Path $DefinitionFile -Leaf))
        }
    }
}