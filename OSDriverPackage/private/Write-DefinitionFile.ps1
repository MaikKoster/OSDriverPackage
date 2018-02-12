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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Definition,

        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName
    )

    process {
        Write-Verbose "Start writing Definition File '$Filename'."
        if (Test-Path $FileName) {
            Remove-Item -Path $FileName -Force
        }

        $DefinitionFile = New-Object System.IO.StreamWriter $FileName
        if ($null -eq $DefinitionFile) {
            Write-Error "Could not create Driver Package Definition file"
        }

        foreach ($Section in $Definition.Keys) {
            Write-Verbose "    Writing Section: [$Section]"
            $DefinitionFile.WriteLine("[$Section]")
            foreach ($Key in ($Definition[$Section]).Keys) {
                if ($Key -match "^Comment_[\d]+") {
                    $DefinitionFile.WriteLine($Definition[$Section][$Key])
                } else {
                    $DefinitionFile.WriteLine("$Key=$($Definition[$Section][$Key])")
                }
            }
            $DefinitionFile.WriteLine()
        }

        $DefinitionFile.Close()
        Write-Verbose "Finished writing Definition File."
    }
}