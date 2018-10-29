Function Clean-OSDriverPackage {
    <#
    .Synopsis
        Checks the supplied Driver Package against the Core Driver Package and cleans up all
        unneeded Drivers.

    .Description
        The Clean-OSDriverPackage CmdLet compares Driver Packages. The supplied Driver Package
        will be evaluated against the supplied Core Driver Package.

        It uses Compare-OSDriverPackage to compare related Drivers in each Driver Package. See
        Compare-OSDriverPackage for more details on the evluation details.

        If there are unneeded Drivers, it will temporarily expand the Driver Package, remove all
        unneeded Drivers, update the Driver Package info file, and compress the updated content.

    #>

    [CmdletBinding()]
    param(
        # Specifies the Core Driver.
        [Parameter(Position=1)]
        [PSCustomObject[]]$CoreDriverPackage,

        # Specifies that should be compared
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path -Path $_.DefinitionFile)})]
        [PSCustomObject]$DriverPackage,

        # Specifies a list of critical PnP IDs, that must be covered by the Core Drivers
        # if found within the Package Driver.
        [string[]]$CriticalIDs = @(),

        # Specifies a list of PnP IDs, that can be safely ignored during the comparison.
        [string[]]$IgnoreIDs = @(),

        # Specifies, if the Driver version should be ignored.
        [switch]$IgnoreVersion,

        # Specifies a list of known mappings of Driver inf files.
        # Some computer vendors tend to rename the original inf files as part of their customization process
        [hashtable]$Mappings = @{},

        # Specifies if the temporary content of the expanded folder should be kept.
        # On default, the content will be removed, after all changes have been applied.
        # Helpful when running several iterations.
        [switch]$KeepFolder,

        # Specifies if the Driver Package is targetting a single architecture only or all
        [ValidateSet('All', 'x86', 'x64', 'ia64')]
        [string]$Architecture = 'All',

        # Specifies if all files, that aren't referenced by any of the Drivers in the supplied Driver Package
        # should be removed.
        [switch]$RemoveUnreferencedFiles,

        # Specifies, if no Driver Package archive file should be created/updated
        # Usefull for temporary evaluation of the content of Driver Packages
        [switch]$NoArchive
    )

    begin {
        # Ensure drivers are loaded
        if ($null -ne $CoreDriverPackage) {
            if ($null -eq $CoreDriverPackage.Drivers) {
                # Need to properly handle the automated unboxing of PowerShell
                $Drivers = Get-OSDriver -Path ($CoreDriverPackage.DriverPackage -replace '.cab|.zip|.def', '.json')
                if ($Drivers.Count -eq 1) {
                    $CoreDriverPackage.Drivers = ,$Drivers
                } else {
                    $CoreDriverPackage.Drivers = $Drivers
                }
            }
        }
    }

    process {
        $script:Logger.Trace("Cleanup driver package ('DriverPackage':'$($DriverPackage.DriverPackage)'")
        $script:Logger.Info("Cleanup driver package '$($DriverPackage.DriverPackage)'.")

        # Validate Driver Package
        if (Test-OSDriverPackage -DriverPackage $DriverPackage) {
            if (Test-Path -Path $DriverPackage.DriverPath -or Test-Path -Path $DriverPackage.DriverArchiveFile) {
                # Get statistical info about the old archive if available
                if (Test-Path -Path $DriverPackage.DriverArchiveFile) {
                    $OldArchive = Get-Item -Path ($DriverPackage.DriverArchiveFile)
                    if ($null -ne $OldArchive) {
                        $OldArchiveSize = $OldArchive.Length
                    } else {
                        $OldArchiveSize = 0
                    }
                } else {
                    $OldArchiveSize = 0
                }

                # Ensure drivers are loaded
                if ($null -eq $DriverPackage.Drivers) {
                    $Drivers = Get-OSDriver -Path ($DriverPackage.DriverInfoFile)
                    if ($Drivers.Count -eq 1) {
                        $DriverPackage.Drivers = ,$Drivers
                    } else {
                        $DriverPackage.Drivers = $Drivers
                    }
                }
                $OldDriverCount = $DriverPackage.Drivers.Count

                # Only continue if the driver package contains any drivers
                if ($DriverPackage.Drivers.Count -gt 0) {
                    # Compare against Core Driver Package(s)
                    if ($null -ne $CoreDriverPackage){
                        $CompareParams = @{
                            CoreDriverPackage = $CoreDriverPackage
                            DriverPackage = $DriverPackage
                            CriticalIDs = $CriticalIDs
                            IgnoreIDs = $IgnoreIDs
                            IgnoreVersion = $IgnoreVersion
                            Mappings = $Mappings
                            Architecture = $Architecture
                        }
                        $null = Compare-OSDriverPackage @CompareParams

                        # Get results that can be removed
                        $RemoveResults = @($DriverPackage.Drivers | Where-Object {$_.Replace})
                    } else {
                        $RemoveResults = @()
                    }

                    # Remove based on architecture, if requested
                    if ($Architecture -ne 'All') {
                        # Remove all Drivers that don't have at least one instance of the requested architecture
                        $RemoveResults += $DriverPackage.Drivers | Where-Object {((($_.HardwareIDs | Group-Object -Property 'Architecture' | Where-Object {$_.Name -eq "$Architecture"}).Count -eq 0) -and (-Not($_.Replace)))}
                    }

                    # Keep copy of remaining Drivers for further evaluation later
                    $RemainingDrivers = $DriverPackage.Drivers | Where-Object {$RemoveResults -notcontains $_} | ForEach-Object {$_.PSObject.Copy()}

                    if ($RemoveResults.Count -gt 0 -or $RemoveUnreferencedFiles.IsPresent) {
                        $script:Logger.Info("Compared $($DriverPackage.Drivers.Count) drivers, $($RemoveResults.Count) can be removed.")

                        if ($RemoveResults.Count -gt 0 -and ($DriverPackage.Drivers.Count -eq $RemoveResults.Count)) {
                            $script:Logger.Info("All drivers from the package can be removed. Removing Driver Package and related files.")

                            # Remove related files
                            Remove-Item -Path ($DriverPackage.DriverPackage -replace '.cab|.zip|.def', '') -Recurse -Force -ErrorAction SilentlyContinue
                            Remove-Item -Path ($DriverPackage.DriverPackage) -Force -ErrorAction SilentlyContinue
                            Remove-Item -Path ($DriverPackage.DefinitionFile) -Force -ErrorAction SilentlyContinue
                            Remove-Item -Path ($DriverPackage.DriverPackage -replace '.cab|.zip|.def', '.json' ) -Force -ErrorAction SilentlyContinue
                            $NewFolderSize = @{
                                Dirs=0
                                Files=0
                                Bytes=0
                            }
                            $NewArchiveSize = 0
                            $NewDriverCount = 0

                        } else {
                            $Expanded = $false
                            # Expand content if necessary
                            if (-Not(Test-Path -Path ($DriverPackage.DriverPath))) {
                                $script:Logger.Info("Temporarily expanding content of '$($DriverPackage.DriverPath)'")
                                Expand-OSDriverPackage -DriverPackage $DriverPackage
                                $Expanded = $true
                            }

                            # Keep some data for statistics
                            $OldFolderSize = Get-FolderSize -Path $DriverPackage.DriverPath

                            # Convert relative path into absolute path
                            $RemoveDriverFiles = $RemoveResults |
                                Select-Object -ExpandProperty DriverFile -Unique |
                                ForEach-Object {
                                    Join-Path -Path ($DriverPackage.DriverPath) -ChildPath $_
                                }

                            foreach ($Remove in $RemoveDriverFiles){
                                Remove-OSDriver -Path $Remove
                            }

                            $AllDriversRemoved = $false
                            if (Test-Path -Path ($DriverPackage.DriverPath)) {
                                # Check if there are drivers left
                                $ExistingDrivers = Get-ChildItem -Path ($DriverPackage.DriverPath) -Recurse -File -Filter '*.inf'
                                if ($ExistingDrivers.Count -eq 0) {
                                    $AllDriversRemoved = $true
                                    Remove-Item $DriverPackage.DriverPath -Force -Recurse
                                }
                            } else {
                                # Driver Package path has been removed.
                                $AllDriversRemoved = $true
                            }

                            if ($AllDriversRemoved) {
                                $script:Logger.Info("All drivers have been removed from Driver package. Removing Driver Package and related files.")
                                # Remove related files
                                Remove-Item -Path ($DriverPackage.DriverArchiveFile) -Force -ErrorAction SilentlyContinue
                                Remove-Item -Path ($DriverPackage.DefinitionFile) -Force
                                Remove-Item -Path ($DriverPackage.DriverInfoFile) -Force
                                $NewFolderSize = @{
                                    Dirs=0
                                    Files=0
                                    Bytes=0
                                }
                                $NewArchiveSize = 0
                                $NewDriverCount = 0
                            } else {
                                if ($RemoveResults.Count -gt 0) {
                                    # Update Driver Package Info file
                                    Read-OSDriverPackage -DriverPackage $DriverPackage

                                    $Definition = $DriverPackage.Definition
                                    If ($Definition.Keys -contains 'PNPIDS') {
                                        $PNPIDs = @{}
                                        $DriverPackage.Drivers | Select-Object -ExpandProperty HardwareIDs |
                                            Group-Object  -Property HardwareID |
                                            ForEach-Object {$_.Group | Select-Object HardwareID, HardwareDescription, Architecture -First 1} |
                                            Sort-Object -Property HardwareID | ForEach-Object {
                                                $HardwareID = $_.HardwareID
                                                if (-Not([string]::IsNullOrEmpty($HardwareID))) {
                                                    $PNPIDs["$HardwareID"] = $_.HardwareDescription
                                                }
                                            }

                                        $DriverPackage.Definition.PNPIDS = $PNPIDs
                                    }
                                }

                                # Cleanup unreferenced files if requested
                                if ($RemoveUnreferencedFiles.IsPresent) {
                                    $ReferencedFiles = @{}
                                    foreach ($Driver in $DriverPackage.Drivers) {
                                        $ParentPath = Join-Path -Path $DriverPackage.DriverPath -ChildPath (Split-Path -Path ($Driver.DriverFile) -Parent)
                                        foreach ($SourceFile in $Driver.SourceFiles) {
                                            $SourceFilePath = (Join-Path -Path $ParentPath -ChildPath $SourceFile).ToUpper()
                                            $ReferencedFiles["$SourceFilePath"] = $null
                                            # Referenced files might still be compressed. Add them as well for easier validation
                                            $SourceFilePath2 = "$($SourceFilePath.Substring(0, ($SourceFilePath.Length - 1)))_"
                                            $ReferencedFiles["$SourceFilePath2"] = $null
                                        }
                                    }

                                    Get-ChildItem -Path $DriverPackage.DriverPath -File -Recurse -Force| ForEach-Object {
                                        $Filename = $_.FullName.ToUpper()
                                        if (-Not($ReferencedFiles.ContainsKey($Filename))) {
                                            $script:Logger.Info("Removing unreferenced file '$($_.FullName)'.")
                                            Remove-Item -Path $_.FullName -Force
                                        }
                                    }
                                }

                                # Remove empty folders
                                $script:Logger.Info("Removing empty folders.")
                                Remove-EmptyFolder -Path $DriverPackage.DriverPath

                                # Update statistics
                                $NewFolderSize = Get-FolderSize -Path $DriverPackage.DriverPath

                                # Create new archive, if there have been some changes
                                $NewArchiveSize = $OldArchiveSize
                                if (-Not($NoArchive.IsPresent)) {
                                    if ((-Not(Test-Path -Path $DriverPackage.DriverPackage)) -or ($OldFolderSize.Dirs -ne $NewFolderSize.Dirs) -or ($OldFolderSize.Files -ne $NewFolderSize.Files) -or ($OldFolderSize.Bytes -ne $NewFolderSize.Bytes)) {
                                        Compress-OSDriverPackage -DriverPackage $DriverPackage -Force -RemoveFolder:($Expanded -and (-Not($KeepFolder.IsPresent)))
                                        $NewArchiveSize = (Get-Item $DriverPackage.DriverArchiveFile).Length
                                    }
                                }

                                $NewDriverCount = $DriverPackage.Drivers.Count
                            }
                        }

                        $Result = [PSCustomObject]@{
                            DriverPackage = $DriverPackage.DriverPackage
                            OldArchiveSize = $OldArchiveSize
                            NewArchiveSize = $NewArchiveSize
                            OldFolderSize = $OldFolderSize
                            NewFolderSize = $NewFolderSize
                            OldDriverCount = $OldDriverCount
                            NewDriverCount = $NewDriverCount
                            RemovedDrivers = $RemoveResults
                            RemainingDrivers = $RemainingDrivers
                        }
                    } else {
                        $script:Logger.Info("Compared $($DriverPackage.Drivers.Count) Drivers, none can be removed.")
                        $Result = [PSCustomObject]@{
                            DriverPackage = $DriverPackage.DriverPackage
                            OldArchiveSize = $OldArchiveSize
                            NewArchiveSize = $OldArchiveSize
                            OldFolderSize = $OldFolderSize
                            NewFolderSize = $OldFolderSize
                            OldDriverCount = $OldDriverCount
                            NewDriverCount = $OldDriverCount
                            RemovedDrivers = @()
                            RemainingDrivers = $RemainingDrivers
                        }
                    }
                } else {
                    $script:Logger.Error("No drivers found in Driver Package '$($DriverPackage.DriverPackage)' found. Skipping further processing.")
                }

            } else {
                $script:Logger.Error("No driver content for Driver Package '$($DriverPackage.DriverPackage)' found. Skipping further processing.")
            }

        } else {
            $script:logger.Error("Invalid Driver Package '$($DriverPackage.DriverPackage)'. Skipping further processing.")
        }

        $script:Logger.Info(($Result | Out-String))
        $Result
    }
}