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
        [Parameter(Mandatory, Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Drivers,

        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -like '*.json'})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Write driver package info file ('Path':'$Path', 'Drivers':$($Drivers | ConvertTo-Json))")

        if (Test-Path $Path) {
            $script:Logger.Debug("Removing old driver package info file at '$Path'.")
            Remove-Item -Path $Path -Force
        }
        $script:Logger.Debug("Writing $($Drivers.Count) drivers to '$Path'.")
        $Drivers | ConvertTo-Json -Depth 4 | Set-Content -Path $Path
    }
}