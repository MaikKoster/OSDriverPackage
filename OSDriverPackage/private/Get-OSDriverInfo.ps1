function Get-OSDriverInfo {
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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
        [Alias("Path")]
        [string]$Filename
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
        Write-Verbose "Start getting Windows Driver info from '$Filename'"
        $DriverFile = Get-Item -Pat $Filename

        #TODO: Get-WindowsDriver requires elevation! Might need to be replaced
        $DriverInfo = Get-WindowsDriver -Online -Driver ($DriverFile.FullName)

        # Get SourceDiskFiles
        $DriverSourceFiles = Get-DriverSourceDiskFile -FileName $DriverFile
        [PSCustomObject]@{
            DriverFile = $DriverFile
            DriverInfo = $DriverInfo
            DriverSourceFiles = $DriverSourceFiles
        }
        Write-Verbose "Finished reading Windows Driver info."
    }
}