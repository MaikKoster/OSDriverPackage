function New-OSDriverPackage {
    <#
    .SYNOPSIS
        Creates a new Driver Package.

    .DESCRIPTION
        The New-OSDriverPackage CmdLet creates a new Driver Package from an existing path, containing
        the drivers. A Driver Package consist of a compressed archive of all drivers, plus a Definition
        file with further information about the drivers inside the Driver Package. Per convention, the
        Definition file and the Driver Package have the same name.
        Additional information about the applicable hardware like Make and Model can be supplied using
        the corresponding parameters. These will be added to the Definition file.
        The list of PnPIDs and corresponding WQL queries will the generated on default, but can be
        optionally be skipped.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of the Driver Package content
        # The Definition File will be named exactly the same as the Driver Package.
        [Parameter(Mandatory, Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the (new) Name of the Driver Package.
        # On Default, the name of the folder that contains the Driver Package content will be used.
        [string]$Name,

        # Specifies the type of archive.
        # Possible values are 'cab' or 'zip'
        [ValidateSet('cab', 'zip')]
        [string]$ArchiveType = 'zip',

        # Specifies generic tag(s) that can be used to further identify the Driver Package.
        [string[]]$Tag = '*',

        # Specifies the excluded generic tag(s).
        # Can be used to e.g. identify specific Core Packages.
        [string[]]$ExcludeTag,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$OSVersion = '*',

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$ExcludeOSVersion,

        # Specifies the supported Architectures.
        # Recommended to use the tags x86, x64 and/or ia64.
        [string[]]$Architecture = '*',

        # Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [string[]]$Make = '*',

        # Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [string[]]$ExcludeMake,

        # Specifies the supported Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [string[]]$Model = '*',

        # Specifies the excluded Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [string[]]$ExcludeModel,

        # Specifies the URL for the Driver Package content.
        [string]$URL,

        # Specifies, if the PnP IDs shouldn't be extracted from the Driver Package
        # Using this switch will prevent the generation of the WQL and PNPIDS sections of
        # the Definition file.
        [switch]$SkipPNPDetection,

        # Specifies if an existing Driver Package should be overwritten.
        [switch]$Force,

        # Specifies, if the source files should be kept, after the Driver Package has been created.
        # On default, all source content will be removed.
        [switch]$KeepFiles,

        # Specifies, if the content should be cleaned after analyzing all Drivers.
        # This will remove all unreferenced files and empty folders
        [switch]$Clean,

        # Specifies, if no Driver Package archive file should be created
        # Usefull for temporary evaluation of the content of Driver Packages
        [switch]$NoArchive
    )

    process {
        $script:Logger.Trace("New driver package ('Path':'$Path', 'Name':'$Name', ArchiveType':'$ArchiveType', 'Tag':'$($Tag -join ',')', 'ExcludeTag':'$($ExcludeTag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'ExcludeOSVersion':'$($ExcludeOSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'ExcludeMake':'$($ExcludeMake -join ',')', 'Model':'$($Model -join ',')', 'ExcludeModel':'$($ExcludeModel -join ',')', 'URL':'$URL', 'SkipPNPDetection':'$SkipPNPDetection', 'Force':'$Force', 'KeepFiles':'$KeepFiles', 'Clean':'$Clean', 'NoArchive':'$NoArchive'")

        $DriverPackagePath = Get-Item -Path $Path.TrimEnd('\')
        $BasePath = Split-Path -Path $DriverPackagePath.FullName -Parent
        if ([string]::IsNullOrEmpty($Name)) {
            $Name = $DriverPackagePath.Basename
        }

        $script:Logger.Info("Creating new driver package from '$($DriverPackagePath.Fullname)'.")

        $DriverPackage = [PSCustomObject]@{
            DefinitionFile = Join-Path -Path $BasePath -ChildPath "$Name.def"
            Definition = $null
            Drivers = @()
            DriverInfoFile = Join-Path -Path $BasePath -ChildPath "$Name.json"
            DriverPath = $DriverPackagePath.Fullname
            DriverArchiveFile = Join-Path -Path $BasePath -ChildPath "$Name.$ArchiveType"
        }

        # Driver Info file
        $script:Logger.Info("Creating new driver package info file.")
        Read-OSDriverPackage -DriverPackage $DriverPackage

        # Definition file
        $DefSettings = @{
            DriverPackagePath = $DriverPackagePath.Fullname
            Name = $Name
            Tag = $Tag
            ExcludeTag = $ExcludeTag
            OSVersion = $OSVersion
            ExcludeOSVersion = $ExcludeOSVersion
            Architecture = $Architecture
            Make = $Make
            ExcludeMake = $ExcludeMake
            Model = $Model
            ExcludeMode = $ExcludeModel
            URL = $URL
            WQL = $null
            PNPIDS = $null
        }

        if ($Force.IsPresent) { $DefSettings.Force = $true}

        if (-Not($SkipPNPDetection.IsPresent)) {
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

            $DefSettings.PNPIDs = $PNPIDs
        }

        $script:Logger.Info("Creating new driver package definition file.")
        $DriverPackage.Definition = New-OSDriverPackageDefinition @DefSettings
        #$DriverPackage.Definition = Read-DefinitionFile -Path $DriverPackage.DefinitionFile

        # Driver Archive
        if ($Clean.IsPresent) {
            # Clean step will take care about compressing files
            $CleanResult = Clean-OSDriverPackage -DriverPackage $DriverPackage -RemoveUnreferencedFiles -KeepFolder:($KeepFiles.IsPresent) -NoArchive:($NoArchive.IsPresent)
            $DriverPackage.DriverArchiveFile = $CleanResult.DriverPackage
        } else {
            # Compress files
            if ($NoArchive.IsPresent) {
                $DriverPackage.DriverArchiveFile = ($DriverPackage.DefinitionFile -replace '.def', ".$ArchiveType")
            } else {
                $script:Logger.Info("Compressing driver package source content.")
                Compress-OSDriverPackage -DriverPackage $DriverPackage -ArchiveType $ArchiveType -Force:($Force.IsPresent) -RemoveFolder:(-Not($KeepFiles.IsPresent))
            }
        }

        $DriverPackage
    }
}