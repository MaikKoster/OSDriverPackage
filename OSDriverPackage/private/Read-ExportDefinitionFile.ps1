Function Read-ExportDefinitionFile {
    <#
    .Synopsis
        Reads Driver Package export definition file.

    .Description

    #>

    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.json')})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Read driver package export definition file ('Path':'$Path')")

        $script:Logger.Debug("Read driver package export definition file from '$Path'.")
        $Definitions = Get-Content -Path $Path | ConvertFrom-Json
        if ($null -eq $Definitions) {
            $Definitions = @()
            $Definitions
        } else {
            $Definitions
        }

    }
}