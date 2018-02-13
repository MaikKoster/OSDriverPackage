function Get-OSDriverInfo {
    <#
    .SYNOPSIS
        Finds specified driver files and returns all PNPIDs.

    .DESCRIPTION
        Finds specified driver files and returns all PNPIDs.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Specifies the name and path for driver files
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
        [Alias("Path")]
        [string]$Filename
    )

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