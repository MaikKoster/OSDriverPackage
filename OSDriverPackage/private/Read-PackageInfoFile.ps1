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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.json')})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        Write-Verbose "Start reading Driver Package Info File '$Path'."

        Get-Content -Path $Path | ConvertFrom-Json

        Write-Verbose "Finished reading Driver Package Info File."
    }
}