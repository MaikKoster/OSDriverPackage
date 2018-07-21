function Apply-OSDriverPackage {
    <#
    .SYNOPSIS
    Applies the specified Driver Package(s) to the computer.

    .DESCRIPTION
    The Apply-OSDriverPackage CmdLet expands the content of the specified Driver Package(s) to the computer.

    .NOTES
    Should be called inside of a Task Sequence.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the path to the root of the Windows directory.
        # Must exist and must contain a subfolder 'Windows'.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path -Path $_) -and (Test-Path -Path (Join-Path -Path $_ -ChildPath 'Windows'))})]
        [string]$WindowsRootPath,

        # Specifies the path to the Driver Package(s).
        # On default, the current directory is used.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be applied, based on the additional conditions.
        [Parameter(ValueFromPipeline)]
        [string]$DriverSourcePath = (Get-Location).Path,

        # Specifies the path to which the specified Driver Package(s) will be extracted to.
        # On default, '$WindowsRootPath\Drivers' will be used
        [Alias('TargetPath')]
        [string]$DriverTempPath,

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

        # Specifies, if the Make (Manufacturer) information of the current computer should be
        # used to select the appropiate driver package.
        [switch]$UseMake,

        # Specifies, if the Model information of the current computer should  be used to select
        # the appropiate driver package.
        [switch]$UseModel,

        # Specifies if the Hardware IDs of the current computer should  be used to select the
        # appropriate Driver Packages.
        [switch]$UseHardwareID,

        # Specifies if the the WQL statements in the driver package definition files should be
        # used to select the appropriate driver packages.
        [switch]$UseWQL,

        # Specifies if unsigned drivers should be added to an x64 image. It overrides the requirement
        # that drivers are installed on X64-based computers must have a digital signture.
        [switch]$EnforceUnsigned,

        # Specifies, if the Driver Packages should only be expanded to the target location.
        # Can be helpful if multiple Driver Packages in separate steps should be applied, but only be
        # injected into the image in one operation.
        [switch]$ExpandOnly
    )

    begin {
        # Get SCCM/MDT Task Sequence environment
        $TSEnvironment = Get-TSEnvironment

        # Ensure folder for temporary drivers exists
        if ([string]::IsNullOrEmpty($DriverTempPath)) {
            $DriverTempPath = Join-Path -Path $WindowsRootPath -ChildPath 'Drivers'
        }

        if (-Not(Test-Path -Path $DriverTempPath)) {
            $null = New-Item -Path $DriverTempPath -ItemType Directory -Force
        }
    }

    process {
        # Identify properties to search for
        $SearchProps = @{
            Path = $DriverSourcePath
            Name = $Name
            Tag = $Tag
            OSVersion = $Tag
            Architecture = $Architecture
            UseWQL = $UseWQL.IsPresent
        }

        # Get Make/Model information
        if (($UseMake.IsPresent) -or ($UseModel.IsPresent)) {
            $Computer = Get-CimInstance -ClassName 'Win32_ComputerSystem' -ErrorAction SilentlyContinue

            if ($null -ne $Computer) {
                if ($UseMake.IsPresent) {
                    $SearchProps['Make'] = $Computer.Manufacturer
                }
                if ($UseModel.IsPresent) {
                    $SearchProps['Model'] = $Computer.Model
                }
            } else {
                $script:Logger.Error("Failed to get Win32_ComputerSystem. Can't filter based on Make/Model.")
            }
        }

        # Get HardwareIDs
        if ($UseHardwareID.IsPresent) {
            $SearchProps['HardwareIDs'] = Get-PnPDevice -HardwareIDOnly
        }

        $DriverPackages = Get-OSDriverPackage @SearchProps

        foreach ($DriverPackage in $DriverPackages) {
            $DriverPackageID = $DriverPackage.Definition.OSDriverPackage.ID
            if ([string]::IsNullOrEmpty($DriverPackageID)) {
                $DriverPackageID = [guid]::NewGuid().Guid
            }
            $DriverPackageTempPath = Join-Path -Path $DriverTempPath -ChildPath $DriverPackageID

            # Expand content
            Expand-OSDriverPackage -Path $DriverPackage.DriverPackage -DestinationPath $DriverPackageTempPath -Force

            if (-Not($ExpandOnly.IsPresent)) {
                # Apply drivers
                Add-WindowsDriver -Path $WindowsRootPath -Recurse -Driver $DriverTempPath
            }
        }
    }
}