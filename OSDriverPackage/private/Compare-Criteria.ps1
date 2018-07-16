function Compare-Criteria {

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns','')]
    param (
        # Specifies the section that contains criteria values
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Section,

        # Specifies the filter values
        [string[]]$Filter,

        # Specifies the name of the property, that is used as an include criteria
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Include,

        # Specifies the name of the property used as an exclude criteria
        [string]$Exclude
    )

    process {
        $script:Logger.Trace("Compare criteria ('Section':'$($Section | ConvertTo-Json -Depth 2)', Filter':'$Filter', 'Include':'$Include', 'Exclude':'$Exclude')")

        $FoundMatch = $false
        if ((($Filter -is [array]) -and ($Filter.Count -gt 0) -and (-Not([string]::IsNullOrEmpty($Filter[0])))) -or (-Not([string]::IsNullOrEmpty($Filter)))) {
            if ($Section.Keys -contains "$Include" ) {
                $IncludeValue = $Section["$Include"]
            } else {
                $IncludeValue = ''
            }
            # Validate Include condition first.
            # At least one must apply.
            if (-Not([string]::IsNullOrEmpty($IncludeValue))) {
                $script:Logger.Trace("Comparing include criteria for '$Include'.")
                if ($IncludeValue -eq '*') {
                    # Include matches everything
                    $FoundMatch = $true
                } else {
                    foreach ($Value in $Filter) {
                        if ($Value -match '\*') {
                            foreach ($IncValue In $IncludeValue.Split(',').Trim()){
                                if ($IncValue -like "$Value") {
                                    $script:Logger.Trace("'$IncValue' matches '$Value'.")
                                    $FoundMatch = $true
                                    Break
                                }
                            }
                        } else {
                            if ($IncludeValue.Split(',').Trim() -contains $Value){
                                $script:Logger.Trace("'$IncludeValue' matches '$Value'.")
                                $FoundMatch = $true
                                Break
                            }
                        }
                    }
                }
            } else {
                $FoundMatch = $false
            }

            # Validate against Exclude if a match was found.
            # Exclude overwrites everything.
            if ([string]::IsNullOrEmpty($Exclude)) {
                if (-Not([string]::IsNullOrEmpty($Include))) {
                    $Exclude = "Exclude$Include"
                }
            }
            if ($Section.Keys -contains "$Exclude" ) {
                $ExcludeValue = $Section["$Exclude"]
            } else {
                $ExcludeValue = ''
            }
            if ($FoundMatch) {
                if (-Not([string]::IsNullOrEmpty($ExcludeValue))) {
                    $script:Logger.Trace("Comparing exclude criteria for '$Exclude'.")
                    foreach ($Value in $Filter) {
                        if ($Value -match '\*') {
                            foreach ($ExcValue In $ExcludeValue.Split(',').Trim()){
                                if ($ExcValue -like "$Value"){
                                    $script:Logger.Trace("'$ExcValue' matches '$Value'.")
                                    $FoundMatch = $false
                                    Break
                                }
                            }
                        } else {
                            if ($ExcludeValue.Split(',').Trim() -contains $Value){
                                $script:Logger.Trace("'$ExcludeValue' matches '$Value'.")
                                $FoundMatch = $false
                                Break
                            }
                        }
                    }
                }
            } else {
                $script:Logger.Trace("'$Include' doesn't match '$Value'.")
            }
        } else {
            # If nothing is set, always include
            $script:Logger.Trace("No criteria specified. Match.")
            $FoundMatch = $true
        }

        $FoundMatch
    }
}