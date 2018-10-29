function Compress-Folder {
    <#
    .SYNOPSIS
        Creates an archive, or zipped file, from specified folder(s).

    .DESCRIPTION
        Creates an archive, or zipped file, from specified folder(s).

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of Folder that should be compressed
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_})]
        [Alias("DriverPath")]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the name and path of the archive.
        # On Default, the name of the folder will be used.
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [Alias("DriverArchiveFile")]
        [string]$Destination,

        # Specifies the type of archive.
        # Possible values are 'cab' or 'zip'
        [ValidateSet('cab', 'zip')]
        [string]$ArchiveType,

        # Specifies if High Compression should be used.
        [switch]$HighCompression,

        # Specifies if the name and path of the archive should be returned.
        [switch]$PassThru,

        # Specifies if the output of the Makecab command should be redirected to the console.
        # Should be used for troubleshooting only.
        [switch]$ShowMakeCabOutput,

        # Specifies if the Makecab definition file should be kept after processing.
        # Should be used for troubleshooting only.
        [switch]$KeepMakeCabFile,

        # Specifies if the source files should be deleted after the archive has been created.
        [switch]$RemoveSource
    )

    process {
        $script:Logger.Trace("Compress folder ('Path':'$Path', 'Destination':'$Destination', ArchiveType':'$ArchiveType', 'HighCompression':'$HighCompression', 'ShowMakeCabOutput':'$ShowMakeCabOutput', 'KeepMakeCabFile':'$KeepMakeCabFile', 'RemoveSource':'$RemoveSource')")

        if ([string]::IsNullOrWhiteSpace($ArchiveType)) {
            if ([string]::IsNullOrWhitespace($Destination)) {
                $Destination = "$((Get-Item -Path $Path).FullName.TrimEnd('\')).zip"
            }

            if ($Destination -like '*.cab') {
                $ArchiveType = 'cab'
            } else {
                $ArchiveType = 'zip'
            }

        } else {
            # ArchiveType takes precedence if specified
            if ([string]::IsNullOrWhitespace($Destination)) {
                $Destination = "$((Get-Item -Path $Path).FullName.TrimEnd('\')).$ArchiveType"
            } else {
                $Destionation = $Destination -replace '.zip|.cab', ".$ArchiveType"
            }
        }

        # Files downloaded from the internet might be blocked.
        # As this can cause very hard to diagnose issues especially with SCCM
        # ensure that all files are unblocked before they are compressed.
        Get-ChildItem $Path -Recurse | Unblock-File

        if ($ArchiveType -eq 'zip') {
            if ($PSCmdlet.ShouldProcess("Creating archive '$Destination'.")) {
                $script:Logger.Debug("Compressing folder '$Path' to '$Destination'.")
                if (Test-Path $Destination) {
                    Remove-Item -Path $Destination -Force
                }
                try {
                    Add-Type -Assembly 'System.IO.Compression.Filesystem'
                    [IO.Compression.ZIPFile]::CreateFromDirectory($Path, $Destination)
                } catch {
                    $script:Logger.Error("Exception while calling 'Compress-Folder'")
                    $script:Logger.Error("$($_.ToString())")
                }
            }
        } else {
            $ArchiveFileName = Split-Path -Path $Destination -Leaf
            $ArchiveBasename = $ArchiveFileName -replace '.zip|.cab', ''
            $DestinationFolder = Split-Path -Path $Destination -Parent
            $script:Logger.Debug('Generating MakeCAB directive file.')
            $DirectiveString = [System.Text.StringBuilder]::new()
            [void]$DirectiveString.AppendLine(';*** MakeCAB Directive file;')
            [void]$DirectiveString.AppendLine('.OPTION EXPLICIT')
            [void]$DirectiveString.AppendLine(".Set CabinetNameTemplate=$ArchiveFileName")
            [void]$DirectiveString.AppendLine(".Set DiskDirectory1=$DestinationFolder")
            [void]$DirectiveString.AppendLine('.Set Cabinet=ON')
            [void]$DirectiveString.AppendLine('.Set Compress=ON')
            if ($HighCompression.IsPresent) {
                [void]$DirectiveString.AppendLine('.Set CompressionType=LZX')
            } else {
                [void]$DirectiveString.AppendLine('.Set CompressionType=MSZIP')
            }
            [void]$DirectiveString.AppendLine('.Set CabinetFileCountThreshold=0')
            [void]$DirectiveString.AppendLine('.Set FolderFileCountThreshold=0')
            [void]$DirectiveString.AppendLine('.Set FolderSizeThreshold=0')
            [void]$DirectiveString.AppendLine('.Set MaxCabinetSize=0')
            [void]$DirectiveString.AppendLine('.Set MaxDiskFileCount=0')
            [void]$DirectiveString.AppendLine('.Set MaxDiskSize=0')

            # Files downloaded from the internet might be blocked.
            # As this can cause very hard to diagnose issues especially with SCCM
            # ensure that all files are unblocked when they are compressed.
            Get-ChildItem $FolderFullName -Recurse | Unblock-File
            $DirectivePath = Join-Path -Path $DestinationFolder -ChildPath "$ArchiveBaseName.ddf"
            Get-ChildItem -Recurse $Folder | Where-Object { -Not($_.psiscontainer)} | Select-Object -ExpandProperty Fullname | Foreach-Object {
                [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($FolderFullName.Length + 1))""")
            }
            if ($PSCmdlet.ShouldProcess("Creating archive '$Destination'.")) {
                $script:Logger.Debug("Compressing folder '$FolderFullName' to '$Destination'.")
                $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
                $script:Logger.Trace($DirectiveString.ToString())
                if ($MakeCabOutput.IsPresent) {
                    makecab /F $DirectivePath
                } else {
                    makecab /F $DirectivePath | Out-Null
                }
                if (-Not($KeepMakeCabFile.IsPresent)) {
                    $script:Logger.Trace('Removing temporary files.')
                    Remove-Item $DirectivePath
                    if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
                    if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
                }
            }
        }

        if ($RemoveSource.IsPresent){
            $script:Logger.Debug('Removing source files.')
            Remove-Item -Path $Folder -Recurse -Force
        }

        if ($PassThru.IsPresent) {
            $Destination
        }
    }
}
