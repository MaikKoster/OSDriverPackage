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
    [CmdletBinding(DefaultParameterSetName='ByDriverPackage')]
    param (
        # Specifies the Driver Package
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ParameterSetName='ByDriverPackage')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path -Path $_.DriverPath) -or (Test-Path -Path $_.DriverArchiveFile)})]
        [PSCustomObject]$DriverPackage,

        # Specifies the path to the Driver Package.
        # If a cab file is specified, the content will be temporarily extracted.
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies if the updated Driver Package object should be returned.
        # Shouldn't be necessary, if the Driver Package was supplied as an object
        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            $script:Logger.Trace("Read driver package ('Path':'$Path'")
        } else {
            $script:Logger.Trace("Read driver package ('DriverPackage':'$($DriverPackage.DriverPackage)'")
        }

        # Get Driver Package if necessary
        if ($null -eq $DriverPackage) {
            $DriverPackage = Get-OSDriverPackage -Path $Path
        }

        # Ensure Driver Package has been properly loaded
        if ($null -ne $DriverPackage) {

            $script:Logger.Info("Reading driver information from driver package '$($DriverPackage.DriverPackage)'.")
            $Expanded = $false

            # Temporarily expand driver package if necessary
            if (([string]::IsNullOrEmpty($DriverPackage.DriverPath)) -or (-Not(Test-Path -Path $DriverPackage.DriverPath))) {
                $script:Logger.Debug("Temporarily expand driver package content.")
                #$DriverPackage.DriverPath = Expand-OSDriverPackage -DriverPackage $DriverPackage -Force
                Expand-OSDriverPackage -DriverPackage $DriverPackage -Force
                $Expanded = $true
            }

            if (Test-Path -Path $DriverPackage.DriverPath) {
                # Get all drivers. Strip of Driver Package Path so Driver path is relative to the package.
                $DriverPackage.Drivers = @(Get-OSDriverFile -Path $DriverPackage.DriverPath |
                            Get-OSDriver |
                            ForEach-Object {
                                $_.DriverFile = ($_.DriverFile -replace [regex]::Escape("$($DriverPackage.DriverPath)\"), '')
                                $_
                            })

                if ($DriverPackage.Drivers.Count -gt 0) {
                    $script:Logger.Info("Updating driver package info file")
                    if ([string]::IsNullOrWhiteSpace($DriverPackage.DriverInfoFile)) {
                        $DriverPackage.DriverInfoFile = "$($DriverPackage.DriverPackage -replace '.zip|.cab|.def', '').json"
                    }

                    Write-PackageInfoFile -Path ($DriverPackage.DriverInfoFile) -Drivers ($DriverPackage.Drivers)
                } else {
                    $script:Logger.Error("No Drivers found.")
                }

                # Remove temporary content
                if ($Expanded) {
                    $script:Logger.Debug("Remove temporary content.")
                    Remove-Item -Path $DriverPackage.DriverPath -Recurse -Force
                    $DriverPackage.DriverPath = ''
                }
            } else {
                $script:Logger.Error("'$($DriverPackage.DriverPath)' not found.")
            }

            # Return Driver Package object if requested
            if ($PassThru.IsPresent) {
                $DriverPackage
            }
        } else {
            $script:Logger.Error("Failed to get driver package. '$Path'.")
            throw "Failed to get driver package '$Path'."
        }
    }
}
