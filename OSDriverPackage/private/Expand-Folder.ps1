function Expand-Folder {
    <#
    .SYNOPSIS
        Expands the specified archive.

    .DESCRIPTION
        Expands the specified archive.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of the archive that should be expanded
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((Test-Path -Path $_) -and ($_ -match '\.(cab|zip)'))})]
        [Alias("DriverArchiveFile")]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the name and path of the folder.
        # On Default, the name of the archive will be used.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [Alias("DriverPath")]
        [string]$Destination,

        # Specifies, if the files should be overwritten, if the destination exists already.
        [switch]$Force
    )

    process {
        $script:Logger.Trace("Expand archive ('Path':'$Path', 'Destination':'$Destination'")

        if ([string]::IsNullOrWhiteSpace($Destination)) {
            $Destination = $Path -replace ".zip|.cab", ''
        }

        if (Test-Path -Path $Destination) {
            if (-Not($Force.IsPresent)) {
                $script:Logger.Error("Archive destination '$Destination' exists already and '-Force' is not specified.")
                throw "Archive destination '$Destination' exists already and '-Force' is not specified."
            }
        } else {
            if ($PSCmdlet.ShouldProcess("Creating folder '$Destination'.")) {
                $null = New-Item -Path $Destination -ItemType Directory
            }
        }

        if ($PSCmdlet.ShouldProcess("Extracting files from '$Path' to '$Destination'.")) {
            if ((Get-Item $Path).Extension -eq ".zip") {
                Add-Type -assembly 'System.IO.Compression.Filesystem'
                [IO.Compression.ZipFile]::ExtractToDirectory($Path, $Destination)
            } else {
                $null = EXPAND "$Path" -F:* "$Destination"
            }
        }

        $Destination
    }
}
