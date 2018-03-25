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
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string[]]$Path,

        # Specifies the Path to which the Driver Package should be expanded.
        # On default, a subfolder with the same name as the Driver Package will be used.
        [Alias('Destination')]
        [string]$DestinationPath,

        # Specifies if an existing folder should be overwritten
        [switch]$Force,

        # Specifies if the archive file should be deleted after it has been expanded.
        [switch]$RemoveArchive,

        # Specifies, if the name and path of the expanded folder should be returned.
        [switch]$Passthru
    )

    begin {
        if (-Not([string]::IsNullOrEmpty($DestinationPath))) {
            $ArchiveDestinationPath = $DestinationPath
        }
    }

    process {
        foreach ($Archive in $Path){
            $script:Logger.Trace("Expand driver package ('Path':'$Path', 'DestinationPath':'$DestinationPath', 'Force':'$Force', 'RemoveArchive':'$RemoveArchive, 'PassThru':'$PassThru'")

            $ArchiveName = (Get-Item $Archive).BaseName
            $ArchivePath = (Get-Item $Archive).FullName.Trim("\")
            if ([string]::IsNullOrEmpty($DestinationPath)) {
                $ArchiveDestinationPath = Split-Path $ArchivePath -Parent
            }
            $ArchiveDestination = Join-Path -Path $ArchiveDestinationPath -ChildPath $ArchiveName
            $script:Logger.Info("Expanding driver package '$Archive' to '$ArchiveDestination'.")
            if (Test-Path $ArchiveDestination) {
                if (-not($Force.IsPresent)) {
                    $script:Logger.Error("Archive destination '$ArchiveDestination' exists already and '-Force' is not specified.")
                    throw "Archive destination '$ArchiveDestination' exists already and '-Force' is not specified."
                }
            } else {
                if ($PSCmdlet.ShouldProcess("Creating folder '$ArchiveDestination'.")) {
                    $null = New-Item -Path $ArchiveDestinationPath -Name $ArchiveName -ItemType Directory
                }
            }

            if ($PSCmdlet.ShouldProcess("Extracting files to '$ArchivePath' to '$ArchiveDestination'.")) {
                if ((Get-Item $Archive).Extension -eq ".zip") {
                    Add-Type -assembly 'System.IO.Compression.Filesystem'
                    [IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $ArchiveDestination)
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
}