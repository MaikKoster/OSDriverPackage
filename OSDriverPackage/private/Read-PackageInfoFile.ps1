Function Read-PackageInfoFile {
    <#
    .Synopsis
        Reads Driver Package information from a file.

    .Description
        Reads detailed information about all drivers in the Driver Package from a file.
        The file is used to speed up the lead time, if Driver related information is needed
        to execute further evaluation/comparison, as Get-OSDriver is ~100 times slower.
        Information is stored in JSON format to reduce size and increase speed.
    #>

    [CmdletBinding()]
    param(
        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.json')})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Read driver package info file ('Path':'$Path')")

        $script:Logger.Debug("Read driver package info file from '$Path'.")
        Get-Content -Path $Path | ConvertFrom-Json
    }
}