Function Write-PackageInfoFile {
    <#
    .Synopsis
        Writes Driver Package information to a file.

    .Description
        Writes detailed information about all drivers in the Driver Package into a file.
        The file is used to speed up the lead time if Driver related information is needed
        to execute further evaluation/comparison, as Get-OSDriver is ~100 times slower.
        Information is stored in JSON format to reduce size and increase speed.
        All existing information will be overwritten.
    #>

    [CmdletBinding()]
    param(
        # Specifies a list of Drivers from the Driver Package
        # The list should be created using Get-OSDriver
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Drivers,

        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -like '*.json'})]
        [Alias("FullName")]
        [string]$Path
    )
    process {
        Write-Verbose "Start writing Driver Package Info File '$Path'."

        if (Test-Path $Path) {
            Remove-Item -Path $Path -Force
        }
        $Drivers | ConvertTo-Json -Depth 4 | Set-Content -Path $Path

        Write-Verbose "Finished writing Driver Package Info File."
    }
}