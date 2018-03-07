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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$CoreDriverPackage,

        # Specifies that should be compared
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_.DriverPackage) -and (((Get-Item $_.DriverPackage).Extension -eq '.cab') -or ((Get-Item $_.DriverPackage).Extension -eq '.zip'))})]
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
        [switch]$KeepFolder
    )

    begin {
        Write-Verbose "Start cleaning Driver Package."
    }

    process {
        $Pkg = (Get-Item -Path ($DriverPackage.DriverPackage))
        $PkgPath = Join-Path -Path ($Pkg.Directory) -ChildPath ($Pkg.BaseName)
        $ArchiveType = $Pkg.Extension -replace '\.' , ''
        $OldArchiveSize = $Pkg.Length
        $OldDriverCount = $DriverPackage.Drivers.Count

        Write-Verbose "  Processing Driver Package '$($DriverPackage.DriverPackage)'."
        $CompareParams = @{
            CoreDriverPackage = $CoreDriverPackage
            DriverPackage = $DriverPackage
            CriticalIDs = $CriticalIDs
            IgnoreIDs = $IgnoreIDs
            IgnoreVersion = $IgnoreVersion
            Mappings = $Mappings
        }
        $ComparisonResults = Compare-OSDriverPackage @CompareParams
        $RemoveResults = $ComparisonResults | Where-Object{$_.Replace}

        if ($RemoveResults.Count -gt 0) {
            Write-Verbose "  Compared $($ComparisonResults.Count) Drivers, $($RemoveResults.Count) can be removed."
            $Expanded = $false
            # Expand content if necessary
            if (-Not(Test-Path $PkgPath)) {
                Expand-OSDriverPackage -Path $Pkg.FullName
                $Expanded = $true
            }

            # Keep some data for statistics
            $OldFolderSize = Get-FolderSize -Path $PkgPath

            # Convert relative path into absolute path
            $RemoveDriverFiles = $RemoveResults |
                Select-Object -ExpandProperty DriverFile -Unique |
                ForEach-Object {
                    Join-Path -Path $PkgPath -ChildPath $_
                }

            foreach ($Remove in $RemoveDriverFiles){
                Remove-OSDriver -Path $Remove
            }

            # Update Driver Package Info file
            Read-OSDriverPackage -Path $PkgPath

            # TODO: Update Definition file. cleanup WQL and PNPIDS sections
            $Definition = $DriverPackage.Definition
            If ($Definition.Keys -contains 'WQL') {
                $Section = $Definition['WQL']
                #TODO Update WQL section
            }
            If ($Definition.Keys -contains 'PNPIDS') {
                $Section = $Definition['WQL']
                #TODO: Update PNPIDS section
            }

            # Update statistics
            $NewFolderSize = Get-FolderSize -Path $PkgPath

            # Create new cab file
            $null = Compress-OSDriverPackage -Path "$PkgPath" -ArchiveType $ArchiveType -Force -RemoveFolder:($Expanded -and (-Not($KeepFolder.IsPresent)))

            $Pkg = (Get-Item $DriverPackage.DriverPackage)
            $NewArchiveSize = $Pkg.Length
            $NewPackage = Get-OSDriverPackage -Path $Pkg.FullName -Verbose:$false
            $NewDriverCount = $NewPackage.Drivers.Count

            [PSCustomObject]@{
                DriverPackage = $DriverPackage.DriverPackage
                OldArchiveSize = $OldArchiveSize
                NewArchiveSize = $NewArchiveSize
                OldFolderSize = $OldFolderSize
                NewFolderSize = $NewFolderSize
                OldDriverCount = $OldDriverCount
                NewDriverCount = $NewDriverCount
                RemovedDrivers = $RemoveResults
            }
        } else {
            Write-Verbose "  Compared $($ComparisonResults.Count) Drivers, none can be removed."
            [PSCustomObject]@{
                DriverPackage = $DriverPackage.DriverPackage
                OldArchiveSize = $OldArchiveSize
                NewArchiveSize = $OldArchiveSize
                OldFolderSize = $OldFolderSize
                NewFolderSize = $OldFolderSize
                OldDriverCount = $OldDriverCount
                NewDriverCount = $OldDriverCount
                RemovedDrivers = @()
            }
        }
    }

    end {
        Write-Verbose "Finished comparing Driver Package."
    }
}