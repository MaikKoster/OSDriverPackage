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
        [Alias("FullName")]
        [string]$Path,

        # Specifies the supported Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$OSVersion,

        # Specifies the excluded Operating System version(s).
        # Recommended to use tags as e.g. Win10-x64, Win7-x86.
        [string[]]$ExcludeOSVersion,

        # Specifies the supported Architectures.
        # Recommended to use the tags x86, x64 and/or ia64.
        [string[]]$Architecture,

        # Specifies generic tag(s) that can be used to further identify the Driver Package.
        [string[]]$Tag,

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
        Write-Verbose "Start creating new Driver Package."
    }

    process {
        Write-Verbose "  Processing path '$Path'."

        # Create a Definition file first
        $DefSettings = @{
            Path = $Path
            OSVersion = $OSVersion
            ExcludeOSVersion = $ExcludeOSVersion
            Architecture = $Architecture
            Tag = $Tag
            Make = $Make
            ExcludeMake = $ExcludeMake
            Model = $Model
            ExcludeMode = $ExcludeModel
            URL = $URL
        }

        if ($Force.IsPresent) { $DefSettings.Force = $true}
        if ($SkipPNPDetection.IsPresent) { $DefSettings.SkipPNPDetection = $true}

        Read-OSDriverPackage -Path $Path

        Write-Verbose "    Creating new Driver Package Definition file."
        New-OSDriverPackageDefinition @DefSettings

        # Compress files
        Write-Verbose "    Compressing Driver Package source content."
        $DriverPackagePath = Compress-Folder -Path $Path -PassThru

        # Remove source files if necessary
        if (-Not($KeepFiles.IsPresent)) {
            if ($PSCmdlet.ShouldProcess("Removing Driver Package source content from '$Path'")) {
                Write-Verbose "    Removing Driver Package source content from '$Path'"
                Remove-Item -Path $Path -Recurse -Force
            }
        }

        if ($PassThru.IsPresent) {
            Get-OSDriverPackage -Path $DriverPackagePath
        }

    }

    end{
        Write-Verbose "Finished creating new Driver Package."
    }
}