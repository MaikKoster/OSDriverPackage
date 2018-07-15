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

        # Specifies the type of archive.
        # Possible values are CAB or ZIP
        [ValidateSet('CAB', 'ZIP')]
        [string]$ArchiveType = 'ZIP',

        # Specifies generic tag(s) that can be used to further identify the Driver Package.
        [string[]]$Tag,

        # Specifies the excluded generic tag(s).
        # Can be used to e.g. identify specific Core Packages.
        [string[]]$ExcludeTag,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$OSVersion,

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$ExcludeOSVersion,

        # Specifies the supported Architectures.
        # Recommended to use the tags x86, x64 and/or ia64.
        [string[]]$Architecture,

        # Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [string[]]$Make,

        # Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        [string[]]$ExcludeMake,

        # Specifies the supported Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [string[]]$Model,

        # Specifies the excluded Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        [string[]]$ExcludeModel,

        # Specifies the URL for the Driver Package content.
        [string]$URL,

        # Specifies, if the PnP IDs shouldn't be extracted from the Driver Package
        # Using this switch will prevent the generation of the WQL and PNPIDS sections of
        # the Definition file.
        [switch]$SkipPNPDetection,

        # Specifies, if Subsystem part of the Hardware ID should be ignored when comparing Drivers
        # Will be added to the OSDrivers section of the definitino file.
        [switch]$IgnoreSubSys,

        # Specifies if an existing Driver Package should be overwritten.
        [switch]$Force,

        # Specifies, if the source files should be kept, after the Driver Package has been created.
        # On default, all source content will be removed.
        [switch]$KeepFiles,

        # Specifies if the name and path of the Driver Package and Definition files should be returned.
        [switch]$PassThru
    )

    process {
        $script:Logger.Trace("New driver package ('Path':'$Path', 'ArchiveType':'$ArchiveType', 'Tag':'$($Tag -join ',')', 'ExcludeTag':'$($ExcludeTag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'ExcludeOSVersion':'$($ExcludeOSVersion -join ',')', 'Architecture':'$($Architecture -join ',')', 'Make':'$($Make -join ',')', 'ExcludeMake':'$($ExcludeMake -join ',')', 'Model':'$($Model -join ',')', 'ExcludeModel':'$($ExcludeModel -join ',')', 'URL':'$URL', 'SkipPNPDetection':'$SkipPNPDetection', 'IgnoreSubSys':'$IgnoreSubSys', 'Force':'$Force', 'KeepFiles':'$KeepFiles', 'PassThru':'$PassThru'")

        $Path = (Get-Item -Path $Path.Trim("\")).FullName

        $script:Logger.Info("Creating new driver package from '$Path'.")

        # Create a Definition file first
        $DefSettings = @{
            Path = $Path
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
            SkipPNPDetection = $SkipPNPDetection
            IgnoreSubSys = $IgnoreSubSys
        }

        if ($Force.IsPresent) { $DefSettings.Force = $true}
        if ($SkipPNPDetection.IsPresent) { $DefSettings.SkipPNPDetection = $true}

        $script:Logger.Info("Creating new driver package info file.")
        Read-OSDriverPackage -Path $Path

        $script:Logger.Info("Creating new driver package definition file.")
        New-OSDriverPackageDefinition @DefSettings

        # Compress files
        $script:Logger.Info("Compressing driver package source content.")
        $DriverPackagePath = Compress-OSDriverPackage -Path $Path -ArchiveType $ArchiveType -Force:($Force.IsPresent) -RemoveFolder:(-Not($KeepFiles.IsPresent)) -Passthru

        if ($PassThru.IsPresent) {
            Get-OSDriverPackage -Path $DriverPackagePath -ReadDrivers
        }
    }
}