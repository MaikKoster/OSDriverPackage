function Copy-OSDriverPackage {
    <#
    .SYNOPSIS
        Copies a Driver Package to a different location.

    .DESCRIPTION
        Copies a Driver Package to a different location. On default, any content that exists at the Destination,
        won't be overwritten. Also only OSD related files (the Driver archvive and the definition file) will be
        copied. This behaviour can be adjust using "Force" and "All" switches.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByObject')]
    param (
        # Specifies the Driver Package, that should be copied.
        [Parameter(Mandatory, ParameterSetName='ByDriverPackage', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$DriverPackage,

        # Specifies the name and path of Driver Package that should be copied.
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((Test-Path $_) -and ($_ -like '*.def'))})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Destination to copy the Driver Packages to
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        # Specifies if any existing content should be overwritten
        [switch]$Force,

        # Specifies if all files should be copiedl.
        # On default, only OSD related content (Driver Definition file and Archive) are copied
        [switch]$All,

        # Specifies, if the copied Driver Package should be returned.
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
            $script:Logger.Trace("Copy driver package ('Path':'$Path', 'Destination':'$Destination', 'Force':'$Force', 'All':'$All', 'Passthru':'$Passthru'")
        } else {
            $script:Logger.Trace("Copy driver package ('DriverPackage':'$($DriverPackage.DefinitionFile)', 'Destination':'$Destination', 'Force':'$Force', 'All':'$All', 'Passthru':'$Passthru'")
        }

        # Get Driver Package
        if ($null -eq $DriverPackage) {
            $DriverPackage = Get-OSDriverPackage -Path $Path
        }

        # Ensure Driver package is valid
        if (Test-OSDriverPackage -DriverPackage $DriverPackage) {
            $script:Logger.Info("Copying driver package '$($DriverPackage.DefinitionFile)' to '$Destination'.")

            if ((Split-Path -Path $DriverPackage.DefinitionFile -Parent) -ne $Destination) {
                $CopyArgs = @{
                    Destination = $Destination
                    Force = $Force.IsPresent
                }

                # Copy Definition File
                $DefinitionFile = $DriverPackage.DefinitionFile
                if (-Not(Test-Path $DefinitionFile)) {
                    $script:Logger.Warn("Definition File '$DefinitionFile' is missing. Creating stub file.")
                    New-OSDriverPackageDefinition -DriverPackagePath $DriverPackageName
                }
                $TargetPath = Join-Path -Path $Destination -ChildPath (Split-Path -Path $DefinitionFile -Leaf)
                if ((-Not(Test-Path -Path $TargetPath)) -or ((Test-Path -Path $TargetPath) -and ($Force.IsPresent))) {
                    $script:Logger.Debug("Copying driver package definition file '$DefinitionFile' to '$Destination'.")
                    Copy-Item @CopyArgs -Path $DefinitionFile
                } else {
                    $script:Logger.Debug("Driver package definition file '$TargetPath' exists already and 'Force' is not specified. Skipping copy operation.")
                }

                # Copy Archive if it exists
                $DriverAchiveFile = $DriverPackage.DriverArchiveFile
                if (Test-Path -Path $DriverAchiveFile) {
                    $TargetPath = Join-Path -Path $Destination -ChildPath (Split-Path -Path $DriverAchiveFile -Leaf)
                    if ((-Not(Test-Path -Path $TargetPath)) -or ((Test-Path -Path $TargetPath) -and ($Force.IsPresent))) {
                        $script:Logger.Debug("Copying driver archive file '$DriverAchiveFile' to '$Destination'.")
                        Copy-Item @CopyArgs -Path $DriverAchiveFile
                    } else {
                        $script:Logger.Debug("Driver archive file '$TargetPath' exists already and 'Force' is not specified. Skipping copy operation.")
                    }
                } else {
                    $script:Logger.Debug("Driver archive file '$DriverAchiveFile' is not present. Skipping copy operation.")
                }

                if ($All.IsPresent) {
                    # Copy Driver Info File
                    $InfoFile = $DriverPackage.DriverInfoFile
                    if (Test-Path -Path $InfoFile) {
                        $TargetPath = Join-Path -Path $Destination -ChildPath (Split-Path -Path $InfoFile -Leaf)
                        if ((-Not(Test-Path -Path $TargetPath)) -or ((Test-Path -Path $TargetPath) -and ($Force.IsPresent))) {
                            $script:Logger.Debug("Copying driver info file '$InfoFile' to '$Destination'.")
                            Copy-Item @CopyArgs -Path $InfoFile
                        } else {
                            $script:Logger.Debug("Driver info file '$TargetPath' exists already and 'Force' is not specified. Skipping copy operation.")
                        }
                    } else {
                        $script:Logger.Debug("Driver info file '$InfoFile' is not present. Skipping copy operation.")
                    }

                    # Copy Drivers
                    $DriverPath = $DriverPackage.DriverPath
                    if (Test-Path -Path $DriverPath) {
                        $TargetPath = Join-Path -Path $Destination -ChildPath (Split-Path -Path $DriverPath -Leaf)
                        if ((-Not(Test-Path -Path $TargetPath)) -or ((Test-Path -Path $TargetPath) -and ($Force.IsPresent))) {
                            $script:Logger.Debug("Copying Drivers from '$DriverPath' to '$Destination'.")
                            Copy-Item @CopyArgs -Path $DriverPath
                        } else {
                            $script:Logger.Debug("Driver path at '$TargetPath' exists already and 'Force' is not specified. Skipping copy operation.")
                        }
                    } else {
                        $script:Logger.Debug("Drivers at '$DriverAchiveFile' are not present. Skipping copy operation.")
                    }
                } else {
                    $script:Logger.Debug("Skipping copy operation for drivers and driver info file.")
                }
            } else {
                $Script:Logger.Warn("Source path '$($DriverPackage.DefinitionFile)' is the same as the destination path '$Destination'. Skipping copy operation.")
            }

        } else {
            $script:logger.Error("Driver Package '$($DriverPackage.DefinitionFile)' is not valid. Skipping copy operation.")
        }

        if ($Passthru.IsPresent) {
            Get-OSDriverPackage -Path (Join-Path -Path $Destination -ChildPath (Split-Path -Path $DefinitionFile -Leaf))
        }
    }
}