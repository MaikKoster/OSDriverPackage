function Remove-NVidiaContent {
    <#
    .SYNOPSIS
        Removes unnecessary NVidia files.

    .DESCRIPTION
        Removes unnecessary files from NVidia graphics driver package.
        Don't use at the moment. Has been copied from original source.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of folder that contains the NVidia driver files
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string[]]$Path
    )

    begin{
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }

        $NVidiaFolders = @("Display.NView",
                        "Display.Optimus",
                        "Display.Update",
                        "DisplayDriverCrashAnalyzer",
                        "GFExperience",
                        "GFExperience.NvStreamSrv",
                        "MSVCRT",
                        "nodejs",
                        "NV3DVision",
                        "NvBackend",
                        "NvCamera",
                        "NvContainer",
                        "NVI2",
                        "NvTelemetry",
                        "NVWMI",
                        "PhysX",
                        "ShadowPlay",
                        "Update.Core")
    }

    process {
        foreach ($Folder in $Path) {
            ForEach ($NVidiaFolder in $NVidiaFolders) {
                if ($PSCmdlet.ShouldProcess("Removing folder '$NVidiaFolder'.")) {
                    Remove-Item -Path $Folder -Include $NVidiaFolder -Recurse
                }
            }
        }
    }
}