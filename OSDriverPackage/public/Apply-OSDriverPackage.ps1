function Apply-OSDriverPackage {
    <#
    .SYNOPSIS
    Applies the specified Driver Package(s) to the current computer.

    .DESCRIPTION
    The Apply-OSDriverPackage CmdLet expands the content of the specified Driver Package(s) to the current computer.

    .EXAMPLE
    PS C:\>Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers'

    Applies all matching Driver Packages to the local computer. Matching methods used are Make, Model,
    HardwareID, and WQL commands as defined within the Driver Package.

    .EXAMPLE
    PS C:\>Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers' -Tag 'Core' -NoMake -NoModel

    Applies all matching Driver Packages to the local computer. Matching methods used are the tag 'Core',
    HardwareID, and WQL commands as defined within the Driver Package. Make and Model information isn't used.

    .EXAMPLE
    PS C:\>Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers' -NoHardwareID -NoWQL

    Applies all matching Driver Packages to the local computer. Matching methods used are Make and Model.
    HardwareID and WQL commands aren't used.

    .NOTES
    Currently this CmdLet only expands the content of the Driver Package to the specified path. It's primary
    purpose is to be used as part of the MDT/ConfigMgr OSD deployment.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be applied, based on the additional conditions
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the path to which the specified Driver Package(s) should be extracted to.
        [Parameter(Mandatory, Position=1)]
        [ValidateNotNullOrEmpty()]
        [Alias('TargetPath')]
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

        # Specifies, if the Make (Manufacturer) information of the current computer should not be
        # used to select the appropiate driver package. On default, the Manufacturer property of
        # the Win32_ComputerSystem class of the current computer will be used to filter the
        # appropriate driver packages.
        [switch]$NoMake,

        # Specifies, if the Model information of the current computer should not be used to select
        # the appropiate driver package. On default, the Model property of the Win32_ComputerSystem
        # class of the current computer will be used to filter the appropriate driver packages.
        [switch]$NoModel,

        # Specifies if the Hardware IDs of the current computer should not be used to select the
        # appropriate Driver Packages. On default, All Hardware IDs of the current computer will be
        # compared against the list of Hardware IDs stored in the driver package definition file.
        # If they match, the driver package will be applied.
        [switch]$NoHardwareID,

        # Specifies if the the WQL statements in the driver package definition files should not be
        # used to select the appropriate driver packages. On default, any existing WQL query will be
        # executed, and if it returns a result, the driver package will be applied.
        [switch]$NoWQL
    )

    process {
        $script:Logger.Trace("Apply driver package ('Path':'$Path', 'Destination':'$Destination', 'Name':'$($Name -join ',')', 'Tag':'$($Tag -join ',')', 'OSVersion':'$($OSVersion -join ',')', 'Make':'$($Make -join ',')', 'Model':'$($Model -join ',')'")

        # Ensure Target-Path exists
        if (-Not(Test-Path -Path $Destination)) {
            $script:Logger.Debug("Create destination path '$Destination'")
            $null = New-Item -ItemType Directory -Path $Destination -Force
        }

        # Identify properties to search for
        $SearchProps = @{
            Path = $Path
            Name = $Name
            Tag = $Tag
            OSVersion = $Tag
            UseWQL = (-Not($NoWQL.IsPresent))
        }

        # Get Make/Model information
        if ((-Not($NoMake.IsPresent)) -or (-Not($NoModel.IsPresent))) {
            $Computer = Get-CimInstance -ClassName 'Win32_ComputerSystem' -ErrorAction SilentlyContinue

            if ($null -ne $Computer) {
                if (-Not($NoMake.IsPresent)) {
                    $SearchProps['Make'] = $Computer.Manufacturer
                }
                if (-Not($NoModel.IsPresent)) {
                    $SearchProps['Model'] = $Computer.Model
                }
            } else {
                $script:Logger.Error("Failed to get Win32_ComputerSystem. Can't filter based on Make/Model.")
            }
        }

        # Get HardwareIDs
        if (-Not($NoHardwareID.IsPresent)) {
            $SearchProps['HardwareIDs'] = Get-PnPDevice -HardwareIDOnly
        }

        Get-OSDriverPackage @SearchProps | Expand-Archive -DestinationPath $Destination

        #TODO: Add ability to install the new drivers if running in the "real" OS.
    }
}