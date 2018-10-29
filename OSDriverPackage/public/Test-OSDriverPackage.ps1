function Test-OSDriverPackage {
    <#
    .SYNOPSIS
        Validates the supplied Driver Package.

    .DESCRIPTION
        Validates the supplied Driver Package.

    .NOTES

    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        # Specifies the Driver Package, that should be compressed.
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((-Not([string]::IsNullOrWhiteSpace($_.DefinitionFile))) -and (Test-Path -Path ($_.DefinitionFile)))})]
        [PSCustomObject]$DriverPackage
    )

    process {
        $Result = $false

        # Definition file is mandatory, as it contains all core information
        if ($null -eq $DriverPackage.Definition) {
            $DriverPackage.Definition = Get-OSDriverPackageDefinition -Path $DriverPackage.DefinitionFile
        }

        if ($null -ne $DriverPackage.Definition) {
            # Either DriverPath or DriverArchiveFile need to exist
            if ([string]::IsNullOrWhiteSpace($DriverPackage.DriverPath)) {
                # Does definition contain a different path
                if (-Not([string]::IsNullOrWhiteSpace($DriverPackage.Definition['OSDriverPackage']['DriverPath']))) {
                    $DriverPackage.DriverPath = $DriverPackage.Definition['OSDriverPackage']['DriverPath']
                } else {
                    $DriverPackage.DriverPath = $DriverPackage.DefinitionFile -replace '.def', ''
                }
            }

            if ([string]::IsNullOrWhiteSpace($DriverPackage.DriverArchiveFile)) {
                # Does definition contain a different path
                if (-Not([string]::IsNullOrWhiteSpace($DriverPackage.Definition['OSDriverPackage']['DriverArchiveFile']))) {
                    $DriverPackage.DriverArchiveFile = $DriverPackage.Definition['OSDriverPackage']['DriverArchiveFile']
                } else {
                    $DriverPackage.DriverArchiveFile = "$($DriverPackage.DefinitionFile -replace '.def', '').zip"
                }
            }

            if ((Test-Path -Path $DriverPackage.DriverPath) -or (Test-Path -Path $DriverPackage.DriverArchiveFile)) {
                # Validate Driver Info file
                if ([string]::IsNullOrWhiteSpace($DriverPackage.DriverInfoFile)) {
                    Read-OSDriverPackage -DriverPackage $DriverPackage
                }

                if (-Not([string]::IsNullOrWhiteSpace($DriverPackage.DriverInfoFile))) {
                    if ($null -eq $DriverPackage.Drivers) {
                        $DriverPackage.Drivers = Get-OSDriver -Path ($DriverPackage.DriverInfoFile)
                    }

                     # Driver Package must contain at least one
                    if ($DriverPackage.Drivers.Count -gt 0) {
                        $Result = $true
                    } else {
                        $script:Logger.Error("No drivers found for '$($DriverPackage.DefinitionFile)' found. Skipping further processing")
                    }
                } else {
                    $script:Logger.Error("No valid driver info file found for Driver Package '$($DriverPackage.DefinitionFile)' found. Skipping further processing")
                }
            } else {
                $script:Logger.Error("No driver content for Driver Package '$($DriverPackage.DefinitionFile)' found. Skipping further processing")
            }
        } else {
            $script:Logger.Error("No valid driver package definition found for '$($DriverPackage.DefinitionFile)' found. Skipping further processing")
        }

        $Result
    }
}