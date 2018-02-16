function Expand-OSDriverPackage {
    <#
    .SYNOPSIS
        Extracts files from a specified DriverPackage.

    .DESCRIPTION
        Extracts files from a specified DriverPackage.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of Driver Package that should be expanded.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string[]]$Path,

        # Specifies the Path to which the Driver Package should be expanded.
        # On default, a subfolder with the same name as the Driver Package will be used.
        [string]$DestinationPath,

        # Specifies if an existing folder should be overwritten
        [switch]$Force,

        # Specifies if the archive file should be deleted after it has been expanded.
        [switch]$RemoveArchive,

        # Specifies, if the name and path of the expanded folder should be returned.
        [switch]$Passthru
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start expanding Driver Package."
    }

    process {
        foreach ($Archive in $Filename){
            Write-Verbose "  Expanding Driver Package '$Archive'."
            $ArchiveName = (Get-Item $Archive).BaseName
            $ArchivePath = (Get-Item $Archive).FullName
            if ([string]::IsNullOrEmpty($DestinationPath)) {
                $DestinationPath = Split-Path $ArchivePath -Parent
            }
            $ArchiveDestination = Join-Path -Path $DestinationPath -ChildPath $ArchiveName

            if (Test-Path $ArchiveDestination) {
                if (-not($Force.IsPresent)) {
                    throw "Archive destination '$ArchiveDestination' exists already and '-Force' is not specified."
                }
            } else {
                if ($PSCmdlet.ShouldProcess("Creating folder '$ArchiveDestination'.")) {
                    $null = New-Item -Path $DestinationPath -Name $ArchiveName -ItemType Directory
                }
            }

            if ($PSCmdlet.ShouldProcess("Extracting files to '$ArchivePath' to '$ArchiveDestination'.")) {
                if ((Get-Item $Archive).Extension -eq ".zip") {
                    Expand-Archive -Path $ArchivePath -DestinationPath $ArchiveDestination
                } else {
                    $null = EXPAND "$ArchivePath" -F:* "$ArchiveDestination"
                }
            }

            if ($RemoveArchive.IsPresent) {
                if ($PSCmdlet.ShouldProcess("Removing archive '$ArchivePath'.")) {
                    Remove-Item -Path $ArchivePath -Force
                }
            }

            if ($Passthru.IsPresent) {
                $ArchiveDestination
            }
        }
    }
    end {
        Write-Verbose "Finished expanding Driver Package."
    }
}