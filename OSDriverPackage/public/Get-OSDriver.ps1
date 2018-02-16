function Get-OSDriver {
    <#
    .SYNOPSIS
        Returns information about the specified driver.

    .DESCRIPTION
        Returns information about the specified driver and the related files.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Specifies the name and path for the driver file
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
        [Alias("FullName")]
        [string]$Path
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start getting Windows Driver info."
    }

    process {
        if ((Split-Path -Path $Path -Leaf) -eq 'autorun.inf') {
            Write-Verbose "  Skipping '$Path'."
        } else {
            Write-Verbose "  Getting Windows Driver info from '$Path'"
            $DriverFile = Get-Item -Pat $Path

            #TODO: Get-WindowsDriver requires elevation! Might need to be replaced
            $DriverInfo = Get-WindowsDriver -Online -Driver ($DriverFile.FullName)

            # Get SourceDiskFiles
            $DriverSourceFiles = Get-DriverSourceDiskFile -Path $DriverFile
            [PSCustomObject]@{
                DriverFile = $DriverFile
                DriverInfo = $DriverInfo
                DriverSourceFiles = $DriverSourceFiles
            }
        }
    }

    end {
        Write-Verbose "Finished reading Windows Driver info."
    }

}