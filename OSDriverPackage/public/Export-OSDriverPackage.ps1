function Export-OSDriverPackage {
    <#
    .SYNOPSIS
        Exports Driver Packages

    .DESCRIPTION

    .NOTES

    #>
    [CmdletBinding(DefaultParameterSetName='ByObject')]
    param (
        # Specifies the Export definition
        [Parameter(Mandatory, Position=0, ParameterSetName='ByObject', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [object]$ExportDefinition,

        # Specifies the Name of the Export definition
        [Parameter(Mandatory, Position=0, ParameterSetName='ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # Specifies the root path for the driver packages
        [Parameter(Mandatory, Position=1, ParameterSetName='ByName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $ExportDefinition = Get-ExportDefinition -Path $Path -Name $Name
        }

        if ($null -ne $ExportDefinition) {
            # Get list of packages by specified filters
            $DriverPackagesFilter = @{
                Path = $ExportDefinition.SourceRoot
                Name = $ExportDefinition.DriverPackageName
                Tag = $ExportDefinition.Tag
                OSVersion = $ExportDefinition.OSVersion
                Architecture = $ExportDefinition.Architecture
                Make = $ExportDefinition.Make
                Model = $ExportDefinition.Model
            }
            $DriverPackages = Get-OSDriverPackage @DriverPackagesFilter

            # Ensure Target Directory exists
            $Destination = $ExportDefinition.TargetRoot
            if (-Not(Test-Path -Path $Destination)) {
                $script:Logger.Info("Creating export destination folder '$Destination'.")
                $null = New-Item -Path $Destination -ItemType Directory -Force
            }

            # Ensure subfolders for packages and Export configuration exists
            $PackageDestination = Join-Path -Path $Destination -ChildPath 'DriverPackages'
            if (-Not(Test-Path -Path $PackageDestination)) {
                $script:Logger.Info("Creating package destination folder '$PackageDestination'.")
                $null = New-Item -Path $PackageDestination -ItemType Directory -Force
            }

            $ExportedPackagesPath = Join-Path -Path $PackageDestination -ChildPath 'DriverPackages.json'
            if (Test-Path -Path $ExportedPackagesPath) {
                #[System.Collections.ArrayList]$ExportedPackages = @(,(Get-Content -Path $ExportedPackagesPath | ConvertFrom-Json))
                [System.Collections.ArrayList]$ExportedPackages = Get-Content -Path $ExportedPackagesPath -Raw | ConvertFrom-Json
            } else {
                [System.Collections.ArrayList]$ExportedPackages = @()
            }

            $DefinitionDestination = Join-Path -Path $Destination -ChildPath 'DefinitionPackages'
            $DefinitionDestination = Join-Path -Path $DefinitionDestination -ChildPath ($ExportDefinition.Id)
            if (-Not(Test-Path -Path $DefinitionDestination)) {
                $script:Logger.Info("Creating package definition destination folder '$DefinitionDestination'.")
                $null = New-Item -Path $DefinitionDestination -ItemType Directory -Force
            }

            #TODO: Check for Duplicate IDs

            # Copy the Driver Packages to the target location if necessary
            foreach ($DriverPackage in $DriverPackages) {
                # Define the names and pathes
                $DriverPackageID = $DriverPackage.Definition.OSDriverPackage.ID
                $DriverPackageSource = $DriverPackage.DriverPackage
                $DriverPackageName = Split-Path -Path $DriverPackageSource -Leaf
                $DriverPackageDestination = Join-Path -Path $PackageDestination -ChildPath $DriverPackageID
                $DefinitionSource = $DriverPackage.DefinitionFile
                $DefinitionName = Split-Path -Path $DefinitionSource -Leaf

                # Ensure Target folder exists
                if (-Not(Test-Path -Path $DriverPackageDestination)) {
                    $null = New-Item -Path $DriverPackageDestination -ItemType Directory -Force
                }

                # Read information about exported packages. Add new driver package if necessary
                $ExportedPackage = $ExportedPackages | Where-Object {$_.Id -eq ($DriverPackage.Definition.OSDriverPackage.ID)}
                if ($null -eq $ExportedPackage) {
                    $ExportedPackage = [PSCustomObject]@{
                        Name = $DriverPackageName
                        Id = $DriverPackageID
                        PackageHash = ''
                        DefinitionHash = ''
                        References = @($ExportDefinition.Id)
                        PackageState = ''
                        DefinitionState = ''
                    }
                    $null = $ExportedPackages.Add($ExportedPackage)
                    #$ExportedPackages += $ExportedPackage
                } else {
                    # Name might have changed
                    $ExportedPackage.Name = $DriverPackageName

                    # Current export referenced?
                    if (-Not($ExportedPackage.References | Where-Object {$_ -eq $ExportDefinition.Id})) {
                        $ExportedPackage.References += $ExportDefinition.Id
                    }
                }

                if (Test-Path -Path $DriverPackageSource) {
                    $PackageSourceHash = Get-FileHash -Path $DriverPackageSource | Select-Object -ExpandProperty Hash
                    $PackageDestinationHash = $ExportedPackage.PackageHash

                    if ($PackageSourceHash -eq $PackageDestinationHash) {
                        $script:Logger.Info("Driver Package '$DriverPackageSource' hasn't changed. No need to copy.")
                        $ExportedPackage.PackageState = 'NoChanges'
                    } else {
                        $script:Logger.Info("Copying Driver Package '$DriverPackageSource' to '$DriverPackageDestination'.")
                        Copy-Item -Path $DriverPackageSource -Destination $DriverPackageDestination -Force
                        $ExportedPackage.PackageHash = $PackageSourceHash
                        if ([string]::IsNullOrEmpty($PackageDestinationHash)) {
                            $ExportedPackage.PackageState = 'Added'
                        } else {
                            $ExportedPackage.PackageState = 'Updated'
                        }
                    }
                } else {
                    $script:Logger.Error("Driver Package '$DriverPackageSource' not found. Unable to copy to '$DriverPackageDestination'.")
                    $ExportedPackage.PackageState = 'Failed'
                }

                $DefinitionSourceHash = Get-FileHash -Path $DefinitionSource | Select-Object -ExpandProperty Hash
                $DefinitionDestinationHash = $ExportedPackage.DefinitionHash

                if ($DefinitionSourceHash -eq $DefinitionDestinationHash) {
                    $script:Logger.Info("Driver Package Definition '$DefinitionSource' hasn't changed. No need to copy.")
                    $ExportedPackage.DefinitionState = 'NoChanges'
                } else {
                    $script:Logger.Info("Copying Driver Package Definition '$DefinitionSource' to '$DriverPackageDestination'.")
                    Copy-Item -Path $DefinitionSource -Destination $DriverPackageDestination -Force
                    $script:Logger.Info("Copying Driver Package Definition '$DefinitionSource' to '$DefinitionDestination'.")
                    Copy-Item -Path $DefinitionSource -Destination $DefinitionDestination -Force
                    $ExportedPackage.DefinitionHash = $DefinitionSourceHash
                    if ([string]::IsNullOrEmpty($DefinitionDestinationHash)) {
                        $ExportedPackage.DefinitionState = 'Added'
                    } else {
                        $ExportedPackage.DefinitionState = 'Updated'
                    }

                    #TODO: Other Definition Packages might need to be updated as well.
                }

                # Update information about exported packages
                if ($ExportedPackage.References -notcontains $ExportDefinition.Id) {
                    $ExportedPackage.References += $ExportDefinition.Id
                }

                #TODO: Handle packages that have been removed from the export

                # Add information to current Export Configuration
                $DP = $ExportDefinition.DriverPackages | Where-Object {$_.Id -eq $ExportedPackage.Id}

                if ($null -eq $DP) {
                    $DP = [PSCustomObject]@{
                        Name = $ExportedPackage.Name
                        Id = $ExportedPackage.Id
                        PackageState = $ExportedPackage.PackageState
                        DefinitionState = $ExportedPackage.DefinitionState
                    }
                    $ExportDefinition.DriverPackages += $DP
                } else {
                    $DP.Name = $ExportedPackage.Name
                    $DP.PackageState = $ExportedPackage.PackageState
                    $DP.DefinitionState = $ExportedPackage.DefinitionState
                }
            }

            # Save changes to the overview of exported packages
            ConvertTo-Json -Depth 4 -InputObject $ExportedPackages | Set-Content -Path $ExportedPackagesPath -Force
            Set-ExportDefinition -ExportDefinition $ExportDefinition -Path $Path
        } else {
            $Script:Logger.Error("No Export Definition found.")
        }
    }

}