# Used to merge the results from the Compare-OSDriver/Compare-OSDriverPackage function
# Venders might split or merge driver files. So there might be multiple results per driver
function Compare-Result {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject[]]$Result
    )

    begin {
        $ResultsToProcess = @()
    }

    process{
        $ResultsToProcess += $Result
    }

    end {
        $ResultsToProcess | Group-Object -Property DriverFile | ForEach-Object {
            if ($_.Count -eq 1) {
                $_.Group
            } else {
                $First = $_.Group | Sort-Object -Property Version -Descending | Select-Object -First 1

                Foreach ($DriverResult in ($_.Group | Sort-Object -Property Version -Descending | Select-Object -Skip 1)) {
                    if ($DriverResult.Replace) {
                        $First.Replace = $true
                    }
                    Foreach ($MissingID in @($First.MissingHardwareIDs)){
                        if (($DriverResult.MissingHardwareIDs.Count -gt 0) -and ($MissingID -notin ($DriverResult.MissingHardwareIDs)))  {
                            # supported by a different driver in the same package
                            # Remove from list of Missing HardwareIDs
                            Write-Verbose "Missing HardwareID '$($MissingID.HardwareID)' is supported by a different Core Driver. Removing from Result ... "
                            $First.MissingHardwareIDs.Remove($MissingID)
                        }
                    }
                }

                if ($First.MissingHardwareIDs.Count -eq 0) {
                    $First.Replace = $true
                }

                $First
            }
        }
    }
}