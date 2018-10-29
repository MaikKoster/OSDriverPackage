function Expand-OSDriverPackage {
    <#
    .SYNOPSIS
        Extracts files from a specified DriverPackage.

    .DESCRIPTION
        Extracts files from a specified DriverPackage.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByDriverPackage')]
    param (
        # Specifies the Driver Package
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='ByDriverPackage')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_.DriverArchiveFile})]
        [PSCustomObject]$DriverPackage,

        # Specifies the name and path of Driver Package that should be expanded.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Path to which the Driver Package should be expanded.
        # On default, a subfolder with the same name as the Driver Package will be used.
        [Alias('Destination')]
        [string]$DestinationPath,

        # Specifies if an existing folder should be overwritten
        [switch]$Force,

        # Specifies if the archive file should be deleted after it has been expanded.
        [switch]$RemoveArchive,

        # Specifies if the updated Driver Package object should be returned.
        # Shouldn't be necessary, if the Driver Package was supplied as an object
        [switch]$PassThru,

        # Specifies if the specified archive should be expanded only, without handling it as a full
        # Driver package. Usefull when temporarily expanding e.g. Dell Family packages for further
        # evaluation. Just wraps the proper handling for cab and zip files.
        [Parameter(ParameterSetName='ByPath')]
        [switch]$ExpandOnly
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            $script:Logger.Trace("Expand driver package ('Path':'$Path', 'DestinationPath':'$DestinationPath', 'Force':'$Force', 'RemoveArchive':'$RemoveArchive")
        } else {
            $script:Logger.Trace("Expand driver package ('DriverPackage':'$($DriverPackage.DefinitionFile)', 'DestinationPath':'$DestinationPath', 'Force':'$Force', 'RemoveArchive':'$RemoveArchive")
        }

        if ($ExpandOnly.IsPresent -and ($Path -match '\.zip|\.cab')) {
            $ExpandArgs = @{
                Path = $Path
                Destination = ($Path -replace '.zip|.cab', '')
                Force = $Force.IsPresent
            }
        } else {
            # Get Driver Package if necessary
            if ($null -eq $DriverPackage) {
                $DriverPackage = Get-OSDriverPackage -Path $Path
            }

            # Ensure Driver Package has been properly loaded
            if ($null -ne $DriverPackage) {
                if (-Not([string]::IsNullOrWhiteSpace($DriverPackage.DriverArchiveFile))) {
                    $DriverArchiveFile = Get-Item -Path $DriverPackage.DriverArchiveFile
                }

                if ($null -ne $DriverArchiveFile) {
                    if (-Not([string]::IsNullOrEmpty($DestinationPath))) {
                        $DriverPackage.DriverPath = $DestinationPath
                    }

                    if ([string]::IsNullOrEmpty($DriverPackage.DriverPath)) {
                        $DriverPackage.DriverPath = ($DriverPackage.DriverArchiveFile -replace '.zip|.cab', '')
                    }

                    $ExpandArgs = @{
                        Path = $DriverArchiveFile.FullName
                        Destination = $DriverPackage.DriverPath
                        Force = $Force.IsPresent
                    }
                } else {
                    $script:Logger.Error("Failed to get driver archive '$($DriverPackage.DriverArchiveFile)'.")
                    throw "Failed to get driver archive '$($DriverPackage.DriverArchiveFile)'."
                }
            } else {
                $script:Logger.Error("Failed to get driver package. '$Path'.")
                throw "Failed to get driver package '$Path'."
            }
        }

        if ($null -ne $ExpandArgs) {
            $DestinationPath = Expand-Folder @ExpandArgs

            if ( (-Not([string]::IsNullOrEmpty($DestinationPath))) -and $RemoveArchive.IsPresent) {
                if ($PSCmdlet.ShouldProcess("Removing archive '$($ExpandArgs.Path)'.")) {
                    Remove-Item -Path ($ExpandArgs.Path) -Force
                }
            }

            if (($null -ne $DriverPackage) -and ($PassThru.IsPresent)) {
                $DriverPackage
            }
        }
    }
}