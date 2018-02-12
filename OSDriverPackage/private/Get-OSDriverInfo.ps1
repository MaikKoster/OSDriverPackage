function Get-OSDriverInfo {
    <#
    .SYNOPSIS
        Finds specified driver files and returns all PNPIDs.

    .DESCRIPTION
        Finds specified driver files and returns all PNPIDs.

    #>
    [CmdletBinding()]
    param (
        # Specifies the path where to search for driver files
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [string]$Path,

        # Specifies the name of the drivers files.
        # The name can include wildcards. Default is '*.inf'
        [string[]]$Files = '*.inf',

        # Specifies if a gridview should be shown to select the driver files
        [switch]$ShowGrid

    )

    process {
        $DriverFiles = Get-OSDriverFile -Path $Path -Files $Files -ShowGrid:$($ShowGrid.IsPresent)

        $DriverInfo = @()
        foreach ($DriverFile in $DriverFiles) {
            Write-Verbose "Getting Windows Driver info from '$($DriverFile.FullName)'"
            $DriverInfo += Get-WindowsDriver -Online -Driver ($DriverFile.FullName)
        }

        if ($ShowGrid.IsPresent) {
            $DriverInfo = $DriverInfo | Select-Object HardwareId,HardwareDescription,Architecture,ProviderName,Version,Date,ClassName,BootCritical,DriverSignature,OriginalFileName | Out-Gridview -Title 'Get-OSDriverINFo Results' -PassThru
        }

        $DriverInfo
    }
}