function Compare-Criteria {

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Specialized.OrderedDictionary]$Section,
        [string[]]$Filter,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Include,
        [string]$Exclude
    )

    $FoundMatch = $false
    if ($null -ne $Filter) {
        if ($Section.Keys -contains "$Include" ) {
            $IncludeValue = $Section["$Include"]
        } else {
            $IncludeValue = ''
        }
        # Validate Include condition first.
        # At least one must apply.
        if (-Not([string]::IsNullOrEmpty($IncludeValue))) {
            Write-Verbose "  Comparing criteria for '$Include'."
            foreach ($Value in $Filter) {
                if ($Value -match '\*') {
                    foreach ($IncValue In $IncludeValue.Split(',').Trim()){
                        if ($IncValue -like "$Value") {
                            Write-Verbose "  '$IncValue' matches '$Value'."
                            $FoundMatch = $true
                            Break
                        }
                    }
                } else {
                    if ($IncludeValue.Split(',').Trim() -contains $Value){
                        Write-Verbose "  '$IncludeValue' matches '$Value'."
                        $FoundMatch = $true
                        Break
                    }
                }
            }
        } else {
            # Not limited by definition
            $FoundMatch = $true
        }

        # Validate against Exclude if a match was found.
        # Exclude overwrites everything.
        if ([string]::IsNullOrEmpty($Exclude)) {
            if (-Not([string]::IsNullOrEmpty($Exclude))) {
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
                Write-Verbose "  Comparing criteria for '$Exclude'."
                foreach ($Value in $Filter) {
                    if ($Value -match '\*') {
                        foreach ($ExcValue In $ExcludeValue.Split(',').Trim()){
                            if ($ExcValue -like "$Value"){
                                Write-Verbose "  '$ExcValue' matches '$Value'."
                                $FoundMatch = $false
                                Break
                            }
                        }
                    } else {
                        if ($ExcludeValue.Split(',').Trim() -contains $Value){
                            Write-Verbose "  '$ExcludeValue' matches '$Value'."
                            $FoundMatch = $false
                            Break
                        }
                    }
                }
            }
        } else {
            Write-Verbose "  '$Include' doesn't match '$Value'."
        }
    } else {
        # If nothing is set, always include
        $FoundMatch = $true
    }

    $FoundMatch
}