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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        # Specifies the type of archive.
        # Possible values are CAB or ZIP
        [ValidateSet('CAB', 'ZIP')]
        [string]$ArchiveType = 'CAB',

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

    begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    process {
        Write-Verbose "Start compressing folder(s)."
        foreach ($Folder in $Path){
            Write-Verbose "  Processing folder '$Folder'."
            $ArchiveBaseName = (Get-Item $Folder).Name
            $DestinationFolder = (Get-Item $Folder).Parent.FullName
            $FolderFullName = (Get-Item $Folder).Fullname


            if ($ArchiveType -eq 'ZIP') {
                $ArchiveFileName = "$ArchiveBaseName.zip"
                $ArchiveFullName = Join-Path -Path $DestinationFolder -ChildPath $ArchiveFileName
                if ($PSCmdlet.ShouldProcess("Creating archive '$ArchiveFullName'.")) {
                    Write-Verbose "  Compressing folder '$FolderFullName' to '$ArchiveFullName'."
                    Compress-Archive -Path "$FolderFullName\*" -DestinationPath "$ArchiveFullName"
                }
            } else {
                $ArchiveFileName = "$ArchiveBaseName.cab"
                $ArchiveFullName = Join-Path -Path $DestinationFolder -ChildPath $ArchiveFileName
                Write-Verbose '  Generating MakeCAB directive file.'
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
                #Remove Streams from Internet downloads
                Get-ChildItem $FolderFullName -Recurse | Unblock-File
                $DirectivePath = Join-Path -Path $DestinationFolder -ChildPath "$ArchiveBaseName.ddf"
                Get-ChildItem -Recurse $Folder | Where-Object { -Not($_.psiscontainer)} | Select-Object -ExpandProperty Fullname | Foreach-Object {
                    [void]$DirectiveString.AppendLine("""$_"" ""$($_.SubString($FolderFullName.Length + 1))""")
                }
                if ($PSCmdlet.ShouldProcess("Creating archive '$ArchiveFullName'.")) {
                    Write-Verbose "  Compressing folder '$FolderFullName' to '$ArchiveFullName'."
                    $DirectiveString.ToString() | Out-File -FilePath $DirectivePath -Encoding UTF8
                    if ($MakeCabOutput.IsPresent) {
                        makecab /F $DirectivePath
                    } else {
                        makecab /F $DirectivePath | Out-Null
                        #cmd /c "makecab /F ""$DirectivePath""" '>nul' # | Out-Null
                    }
                    if (-Not($KeepMakeCabFile.IsPresent)) {
                        Remove-Item $DirectivePath
                        if (Test-Path 'setup.inf') {Remove-Item 'setup.inf' -Force}
                        if (Test-Path 'setup.rpt') {Remove-Item 'setup.rpt' -Force}
                    }
                }
            }

            if ($RemoveSource.IsPresent){
                Write-Verbose ' Removing source files.'
                Remove-Item -Path $Folder -Recurse -Force
            }

            if ($PassThru.IsPresent) {
                $ArchiveFullName
            }
        }

        Write-Verbose "Finished compressing folder(s)."
    }
}