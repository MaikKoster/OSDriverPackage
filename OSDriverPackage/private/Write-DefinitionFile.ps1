Function Write-DefinitionFile {
    <#
    .Synopsis
        Writes a Driver Package definition file.

    .Description
        Writes a Driver Package definition file.
        Any existing content will be overwritten.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Definition,

        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Write driver package definition file ('Path':'$Path', 'Definition':$($Definition | ConvertTo-Json))")

        if (Test-Path $Path) {
            $script:Logger.Debug("Removing old driver package definition file at '$Path'.")
            Remove-Item -Path $Path -Force
        }

        $script:Logger.Debug("Writing supplied definition to '$Path'.")
        $DefinitionFile = New-Object System.IO.StreamWriter $Path
        if ($null -eq $DefinitionFile) {
            $script:Logger.Error("Failed to create driver package definition file '$Path'.")
            Write-Error "Failed to create driver package definition file '$Path'."
        }

        foreach ($Section in $Definition.Keys) {
            $script:Logger.Trace("Writing section: [$Section]")
            $DefinitionFile.WriteLine("[$Section]")
            foreach ($Key in ($Definition[$Section]).Keys) {
                if ($Key -match "^Comment_[\d]+") {
                    $script:Logger.Trace("Writing comment: $Definition[$Section][$Key]")
                    $DefinitionFile.WriteLine($Definition[$Section][$Key])
                } else {
                    $script:Logger.Trace("Writing key: $Key, value: $($Definition[$Section][$Key])")
                    $DefinitionFile.WriteLine("$Key = $($Definition[$Section][$Key])")
                }
            }
            $DefinitionFile.WriteLine()
        }

        $DefinitionFile.Close()
    }
}