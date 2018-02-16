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
        [ValidateScript({(Test-Path $_ -and (Get-Item $_).PSIsContainer)})]
        [Alias("FullName")]
        [string]$Path,

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

        if ((Test-Path "$Path.cab") -and (-Not($Force.IsPresent))) {
            throw "Archive '$Path.cab' exists already and '-Force' is not specified."
        }

        Compress-Folder -Path $Path -HighCompression -PassThru -Force -Verbose:$false

        if ($RemoveFolder.IsPresent) {
            if ($PSCmdlet.ShouldProcess("Removing folder '$Path'.")) {
                $null = Remove-Item -Path $Path -Recurse -Force
            }
        }

    }
    end {
        Write-Verbose "Finished compressing Driver Package."
    }
}