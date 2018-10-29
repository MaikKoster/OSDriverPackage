function Compress-OSDriverPackage {
    <#
    .SYNOPSIS
        Compresses the specified Driver Package into a zip/cab file.

    .DESCRIPTION
        Compresses the specified Driver Package into a zip/cab file.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName="ByDriverPackage")]
    param (
        # Specifies the Driver Package, that should be compressed.
        [Parameter(Mandatory, ParameterSetName='ByDriverPackage', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_.DriverPath})]
        [PSCustomObject]$DriverPackage,

        # Specifies the name and path of Driver Package that should be compressed.
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({((Test-Path $_) -and ($_ -like '*.def'))})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the (new) Name of the Driver archive.
        # On Default, the name of the folder that contains the drivers will be used.
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
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            $script:Logger.Trace("Compress driver package ('Path':'$Path', 'Name':'$Name', 'ArchiveType':'$ArchiveType', 'Force':'$Force', 'RemoveFolder':'$RemoveFolder, 'Passthru':'$Passthru'")
        } else {
            $script:Logger.Trace("Compress driver package ('DriverPackage':'$($DriverPackage.DefinitionFile)', 'Name':'$Name', 'ArchiveType':'$ArchiveType', 'Force':'$Force', 'RemoveFolder':'$RemoveFolder, 'Passthru':'$Passthru'")
        }

        # Get Driver Package
        if ($null -eq $DriverPackage) {
            $DriverPackage = Get-OSDriverPackage -Path $Path
        }

        $script:Logger.Info("Compressing driver package '$($DriverPackage.DriverPath)'.")

        # CAB only supports <2GB
        if ($ArchiveType -eq 'CAB'){
            $FolderSize  = Get-FolderSize -Path ($DriverPackage.DriverPath)
            if ($FolderSize.Bytes -ge 2GB) {
                $script:Logger.Info("Driver package contains more than 2GB of data. Switching ArchiveType to zip.")
                $ArchiveType = 'ZIP'
            }
        }

        if ([string]::IsNullOrEmpty($Name)) {
            $ArchiveFilename = "$($DriverPackage.DriverPath).$ArchiveType"
        } else {
            $ArchiveFilename = Join-Path -Path (Split-Path -Path ($DriverPackage.DriverPath) -Parent) -ChildPath "$Name.$ArchiveType"
        }

        if ((Test-Path -Path $ArchiveFilename) -and (-Not($Force.IsPresent))) {
            $script:Logger.Error("Archive '$ArchiveFilename' exists already and '-Force' is not specified.")
            throw "Archive '$ArchiveFilename' exists already and '-Force' is not specified."
        }

        $DriverPackage.DriverArchiveFile = Compress-Folder -Path $DriverPackage.DriverPath -Destination $ArchiveFilename -ArchiveType $ArchiveType -HighCompression -PassThru -Verbose:$false

        if ($RemoveFolder.IsPresent) {
            # Only remove if archive has been created successfully
            if ((-Not([string]::IsNullOrWhiteSpace($DriverPackage.DriverArchiveFile))) -and (Test-Path -Path ($DriverPackage.DriverArchiveFile))) {
                if ($PSCmdlet.ShouldProcess("Removing folder '$($DriverPackage.DriverPath)'.")) {
                    # Need to make sure that the path supplied is not $null, otherwise it will delete from the current path.
                    if (-Not([string]::IsNullOrWhiteSpace($DriverPackage.DriverPath))) {
                        $script:Logger.Info("Removing folder '$($DriverPackage.DriverPath)'.")
                        $null = Remove-Item -Path ($DriverPackage.DriverPath) -Recurse -Force
                    }
                }
            } else {
                $script:Logger.Warn("Archive '$ArchiveFilename' has not been created successfully. Skipping removal of '$($DriverPackage.DriverPath)'.")
            }
        }

        if ($Passthru.IsPresent) {
            $DriverPackage
        }
    }
}