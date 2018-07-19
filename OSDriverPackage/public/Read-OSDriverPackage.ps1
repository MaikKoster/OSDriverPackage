function Read-OSDriverPackage {
    <#
    .SYNOPSIS
        Scans for all drivers in a Driver package and creates info file.

    .DESCRIPTION
        The Read-OSDriverPackage CmdLet scans all drivers in the specified Driver Package and creates
        an info file cointaining useful information for further evaluation/comparison, as getting the
        Driver Details is a very time consuming process.


    .NOTES

    #>
    [CmdletBinding()]
    param (
        # Specifies the path to the Driver Package.
        # If a cab file is specified, the content will be temporarily extracted.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies if the Driver Package should be returned
        [switch]$PassThru
    )

    process {
        $script:Logger.Trace("Read driver package ('Path':'$Path', 'PassThru':'$PassThru'")

        $script:Logger.Info("Reading driver information from driver package '$Path'.")
        $DriverPackage = Get-Item -Path ($Path.TrimEnd('\'))

        # Temporily expand driver package if necessary
        $Expanded = $false
        if (($DriverPackage.Extension -eq '.cab') -or ($DriverPackage.Extension -eq '.zip')) {
            if (Test-Path ($DriverPackage.Fullname -replace "$($DriverPackage.Extension)", '')) {
                $DriverPackage = Get-Item ($DriverPackage.Fullname -replace "$($DriverPackage.Extension)", '')
            } else {
                $script:Logger.Debug("Temporarily expand driver package content.")
                $DriverPackage = Get-Item (Expand-OSDriverPackage -Path $DriverPackage.FullName -Force -Passthru)
                $Expanded = $true
            }
        }

        # Get all drivers. Strip of Driver Package Path so Driver path is relative to the package.
        $Drivers = Get-OSDriverFile -Path $DriverPackage.FullName |
                    Get-OSDriver |
                    ForEach-Object {
                        $_.DriverFile = ($_.DriverFile -replace [regex]::escape("$($DriverPackage.Fullname)\"), '')
                        $_
                    }

        $script:Logger.Info("Updating driver package info file")
        Write-PackageInfoFile -Path "$($DriverPackage.Fullname).json" -Drivers $Drivers

        # Remove temporary content
        if ($Expanded) {
            $script:Logger.Debug("Remove temporary content.")
            Remove-Item -Path $DriverPackage -Recurse -Force
        }

        if ($PassThru.IsPresent){
            Get-OSDriverPackage -Path $DriverPackage -ReadDrivers
        }
    }
}
