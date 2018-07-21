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
        # Specifies the name and path of Folder that should be compress
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string[]]$Path,

        # Specifies the name of the archive.
        # On Default, the name of the folder will be used.
        [string]$Name,

        # Specifies the type of archive.
        # Possible values are CAB or ZIP
        [ValidateSet('CAB', 'ZIP')]
        [string]$ArchiveType = 'ZIP',

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
        $script:Logger.Trace("Compress folder ('Path':'$Path', 'Name':'$Name', ArchiveType':'$ArchiveType', 'HighCompression':'$HighCompression', 'PassThru':'$PassThru', 'ShowMakeCabOutput':'$ShowMakeCabOutput', 'KeepMakeCabFile':'$KeepMakeCabFile', 'RemoveSource':'$RemoveSource')")

        foreach ($Folder in $Path){
            if ([string]::IsNullOrEmpty($Name)) {
                $ArchiveBaseName = (Get-Item $Folder).Name
            } else {
                $ArchiveBaseName = $Name
            }
            $DestinationFolder = (Get-Item $Folder).Parent.FullName.TrimEnd('\')
            $FolderFullName = (Get-Item $Folder).Fullname.TrimEnd('\')

            if ($ArchiveType -eq 'ZIP') {
                $ArchiveFileName = "$ArchiveBaseName.zip"
                $ArchiveFullName = Join-Path -Path $DestinationFolder -ChildPath $ArchiveFileName
                if ($PSCmdlet.ShouldProcess("Creating archive '$ArchiveFullName'.")) {
                    $script:Logger.Debug("Compressing folder '$FolderFullName' to '$ArchiveFullName'.")
                    if (Test-Path $ArchiveFullName) {
                        Remove-Item -Path $ArchiveFullName -Force
                    }
                    Add-Type -Assembly 'System.IO.Compression.Filesystem'
                    [IO.Compression.ZIPFile]::CreateFromDirectory($FolderFullName, $ArchiveFullName)
                }
            } else {
                $ArchiveFileName = "$ArchiveBaseName.cab"
                $ArchiveFullName = Join-Path -Path $DestinationFolder -ChildPath $ArchiveFileName
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
                if ($PSCmdlet.ShouldProcess("Creating archive '$ArchiveFullName'.")) {
                    $script:Logger.Debug("Compressing folder '$FolderFullName' to '$ArchiveFullName'.")
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
                $ArchiveFullName
            }
        }
    }
}