function Compress-OSDriverPackage {
    <#
    .SYNOPSIS
        Compresses the specified Driver Package into a cab file.

    .DESCRIPTION
        Compresses the specified Driver Package into a cab file.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of Driver Package that should be compressed.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((Test-Path $_) -and ((Get-Item $_).PSIsContainer))})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the (new) Name of the Driver Package.
        # On Default, the name of the folder that contains the Driver Package content will be used.
        [string]$Name,

        # Specifies the type of archive.
        # Possible values are CAB or ZIP
        [ValidateSet('CAB', 'ZIP')]
        [string]$ArchiveType = 'ZIP',

        # Specifies if an existing archive should be overwritten
        [switch]$Force,

        # Specifies if the original folder should be deleted after it has been compressed.
        [switch]$RemoveFolder,

        # Specifies, if the name and path of the compressed archive should be returned.
        [switch]$Passthru
    )

    process {
        $script:Logger.Trace("compress driver package ('Path':'$Path', 'Name':'$Name', ArchiveType':'$ArchiveType', 'Force':'$Force', 'RemoveFolder':'$RemoveFolder', 'Passthru':'$Passthru'")
        $script:Logger.Info("Compressing driver package '$Path'.")

        # CAB only supports <2GB
        if ($ArchiveType -eq 'CAB'){
            $FolderSize  = Get-FolderSize -Path $Path
            if ($FolderSize.Bytes -ge 2GB) {
                $script:Logger.Info("Driver package contains more than 2GB of data. Switching ArchiveType to zip.")
                $ArchiveType = 'ZIP'
            }
        }

        if ([string]::IsNullOrEmpty($Name)) {
            $ArchiveFilename = "$Path.$ArchiveType"
        } else {
            $ArchiveFilename = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath "$Name.$ArchiveType"
        }

        if ((Test-Path -Path $ArchiveFilename) -and (-Not($Force.IsPresent))) {
            $script:Logger.Error("Archive '$ArchiveFilename' exists already and '-Force' is not specified.")
            throw "Archive '$ArchiveFilename' exists already and '-Force' is not specified."
        }

        $ArchivePath = Compress-Folder -Path $Path -Name $Name -ArchiveType $ArchiveType -HighCompression -PassThru -Verbose:$false

        if ($RemoveFolder.IsPresent) {
            if ($PSCmdlet.ShouldProcess("Removing folder '$Path'.")) {
                $script:Logger.Info("Removing folder '$Path'.")
                $null = Remove-Item -Path $Path -Recurse -Force
            }
        }

        if ($Passthru.IsPresent) {
            $ArchivePath
        }
    }
}