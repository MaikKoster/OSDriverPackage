function Copy-OSDriverPackage {
    <#
    .SYNOPSIS
        Copies Driver Packages to a different location.

    .DESCRIPTION

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the path to the Driver Package.
        # If a folder is specified, all Driver Packages within that folder and subfolders
        # will be returned, based on the additional conditions
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
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

        # Filters the Driver Packages by Make(s)/Vendor(s)/Manufacture(s).
        # Use values from Manufacturer property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Dell*
        [string[]]$Make,

        # Filters the Driver Packages by Model(s)
        # Use values from Model property from Win32_ComputerSystem.
        # Wildcards are allowed e.g. *Latitude*
        [string[]]$Model
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start copying Driver Packages to '$Destination'."
    }

    process {
        Write-Verbose "  Processing path '$Path'."

        $DriverPackages = Get-OSDriverPackage -Path $Path -Name $Name -OSVersion $OSVersion -Tag $Tag -Make $Make -Model $Model

        Foreach ($DriverPackage in $DriverPackages){
            #TODO: Update to use Robocopy. Faster and more reliable
            $DriverPackageName = $DriverPackage.DriverPackage
            Write-Verbose "    Copying Driver Package '$DriverPackageName'."
            Copy-Item -Path $DriverPackageName -Destination $Destination
            $DefinitionFile = $DriverPackage.DefinitionFile
            if (-Not(Test-Path $DefinitionFile)) {
                Write-Warning "    Definition File '$DefinitionFile' is missing. Creating stub file."
                New-OSDriverPackageDefinition -DriverPackagePath $DriverPackageName
            }
            Write-Verbose "    Copying Definition file '$DefinitionFile'."
            Copy-Item -Path $DefinitionFile -Destination $Destination
        }
    }
    end {
        Write-Verbose "Finished copying Driver Package."
    }
}