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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("Path")]
        [string]$DriverPackageSourcePath,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$OSVersion,

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$ExcludeOSVersion,

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

        # Specifies if a grid should be shown to select the inf files and drivers.
        [switch]$ShowGrid,

        # Specifies, if the PnP IDs shouldn't be extracted from the Driver Package
        # Using this switch will prevent the generation of the WQL and PNPIDS sections of
        # the Definition file.
        [switch]$SkipPNPDetection,

        # Specifies if an existing Driver Package should be overwritten.
        [switch]$Force,

        # Specifies, if the source files should be kept, after the Driver Package has been created.
        # On default, all source content will be removed.
        [switch]$KeepFiles,

        # Specifies if the name and path of the Driver Package and Definition files should be returned.
        [switch]$PassThru
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    process {
        Write-Verbose "Start creating new Driver Package from '$DriverPackageSourcePath'."
        $DriverPackageName = Split-Path $DriverPackageSourcePath -Leaf

        # Create a Definition file first
        $DefSettings = @{
            Path = $DriverPackageSourcePath
            PassThru = $true
            OSVersion = $OSVersion
            ExcludeOSVersion = $ExcludeOSVersion
            Make = $Make
            ExcludeMake = $ExcludeMake
            Model = $Model
            ExcludeMode = $ExcludeModel
            URL = $URL
        }

        $PkgSettings = @{
            Path = $DriverPackageSourcePath
            PassThru = $false
        }

        if ($Force.IsPresent) { $DefSettings.Force = $true}
        if ($ShowGrid.IsPresent) { $DefSettings.ShowGrid = $true}
        if ($SkipPNPDetection.IsPresent) { $DefSettings.SkipPNPDetection = $true}

        Write-Verbose "  Creating new Driver Package Definition file."
        $DefinitionFile = New-OSDriverPackageDefinition @DefSettings

        # Compress files
        Write-Verbose "  Compressing Driver Package source content."
        #$DriverPackagePath = Compress-Folder @PkgSettings
        Compress-Folder @PkgSettings

        # Remove source files if necessary
        if (-Not($KeepFiles.IsPresent)) {
            if ($PSCmdlet.ShouldProcess("Removing Driver Package source content from '$DriverPackageSourcePath'")) {
                Write-Verbose "  Removing Driver Package source content from '$DriverPackageSourcePath'"
                Remove-Item -Path $DriverPackageSourcePath -Recurse -Force
            }
        }

        if ($PassThru.IsPresent) {
            $Result = [PSCustomObject]@{
                DriverPackage = $DriverPackagePath
                DriverPackageDefinitionFile = $DefinitionFile
                DriverPackageSourcePath = ''
            }

            if ($KeepFiles.IsPresent) {
                $Result.DriverPackageSourcePath = $DriverPackageSourcePath
            }

            $Result
        }

        Write-Verbose "Finished creating new Driver Package."
    }
}