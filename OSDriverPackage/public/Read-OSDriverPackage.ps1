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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies if the Driver Package should be returned
        [switch]$PassThru
    )
    begin {
        Write-Verbose "Start Reading Driver Package '$Path'."
    }

    process {
        $DriverPackage = Get-Item -Path $Path

        # Temporily expand driver package if necessary
        if ($DriverPackage.Extension -eq '.cab') {
            $DriverPackage = Get-Item (Expand-OSDriverPackage -Path $DriverPackage.FullName -Force -Passthru)
            $Expanded = $true
        }

        $Drivers = Get-OSDriverFile -Path $DriverPackage.FullName | Get-OSDriver

        Write-PackageInfoFile -Path "$($DriverPackage.Fullname).json" -Drivers $Drivers

        # Remove temporary content
        if ($Expanded) {
            Remove-Item -Path $DriverPackage -Recurse -Force
        }

        if ($PassThru.IsPresent){
            Get-OSDriverPackage -Path $DriverPackage
        }
    }

    end {
        Write-Verbose "Finished Reading Driver Package."
    }
}
