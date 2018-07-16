Function Write-ExportDefinitionFile {
    <#
    .Synopsis
        Writes Driver Package export information to a file.

    .Description

    #>

    [CmdletBinding()]
    param(
        # Specifies a list of Drivers from the Driver Package
        # The list should be created using Get-OSDriver
        [Parameter(Mandatory, Position=1, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Definitions,

        # Specifies the name and path of the Definition file.
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -like '*.json'})]
        [Alias("FullName")]
        [string]$Path
    )

    begin {
        $script:Logger.Trace("Write driver package export definition file ('Path':'$Path', 'Definitions':$($Definitions | ConvertTo-Json))")
        # Get current configuration


        if (Test-Path -Path "$Path" ) {
            [System.Collections.ArrayList]$CurrentDefinitions = @(Read-ExportDefinitionFile -Path $Path)
        } else {
            [System.Collections.ArrayList]$CurrentDefinitions = @()
        }
        $Updated = 0
        $Added = 0
    }

    process {
        # Iterate through supplied definitions
        foreach ($Definition in $Definitions) {
            $OldDefinition = $CurrentDefinitions | Where-Object {$_.Id -eq $Definition.Id}

            if ($null -ne $OldDefinition) {
                $null = $CurrentDefinitions.Remove($OldDefinition)
                $Updated++
            } else {
                $Added++
            }

            $null = $CurrentDefinitions.Add($Definition)
        }
    }

    end {
        if (Test-Path $Path) {
            $null = Remove-Item -Path $Path -Force
        }
        $script:Logger.Debug("Saving driver package export definitions to '$Path'. Added: $Added, Updated: $Updated")
        ConvertTo-Json -Depth 4 -InputObject $CurrentDefinitions | Set-Content -Path $Path -Force
    }
}