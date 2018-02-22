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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
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

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start compressing Driver Package."
    }

    process {
        Write-Verbose " Compressing Driver Package '$Path'."

        # CAB only supports <2GB
        if ($ArchiveType -eq 'CAB'){
            $FolderSize  = Get-FolderSize -Path $Path
            if ($FolderSize.Bytes -ge 2GB) {
                Write-Verbose " Driver Package contains more than 2GB of data. Switching to zip."
                $ArchiveType = 'ZIP'
            }
        }

        if ((Test-Path "$Path.$ArchiveType") -and (-Not($Force.IsPresent))) {
            throw "Archive '$Path.$ArchiveType' exists already and '-Force' is not specified."
        }

        Compress-Folder -Path $Path -ArchiveType $ArchiveType -HighCompression -PassThru -Verbose:$false

        if ($RemoveFolder.IsPresent) {
            if ($PSCmdlet.ShouldProcess("Removing folder '$Path'.")) {
                Write-Verbose " Removing folder '$Path'."
                $null = Remove-Item -Path $Path -Recurse -Force
            }
        }

    }
    end {
        Write-Verbose "Finished compressing Driver Package."
    }
}