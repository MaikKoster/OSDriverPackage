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
        $script:Logger.Trace("compress driver package ('Path':'$Path', 'ArchiveType':'$ArchiveType', 'Force':'$Force', 'RemoveFolder':'$RemoveFolder', 'Passthru':'$Passthru'")
        $script:Logger.Info("Compressing driver package '$Path'.")

        # CAB only supports <2GB
        if ($ArchiveType -eq 'CAB'){
            $FolderSize  = Get-FolderSize -Path $Path
            if ($FolderSize.Bytes -ge 2GB) {
                $script:Logger.Info("Driver package contains more than 2GB of data. Switching ArchiveType to zip.")
                $ArchiveType = 'ZIP'
            }
        }

        if ((Test-Path "$Path.$ArchiveType") -and (-Not($Force.IsPresent))) {
            $script:Logger.Error("Archive '$Path.$ArchiveType' exists already and '-Force' is not specified.")
            throw "Archive '$Path.$ArchiveType' exists already and '-Force' is not specified."
        }

        Compress-Folder -Path $Path -ArchiveType $ArchiveType -HighCompression -PassThru -Verbose:$false

        if ($RemoveFolder.IsPresent) {
            if ($PSCmdlet.ShouldProcess("Removing folder '$Path'.")) {
                $script:Logger.Info("Removing folder '$Path'.")
                $null = Remove-Item -Path $Path -Recurse -Force
            }
        }
    }
}