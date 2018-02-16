function Get-OSDriverPackageDefinition {
    <#
    .SYNOPSIS
        Gets a Driver Package Definition.

    .DESCRIPTION
        The Get-OSDriverPackageDefinition CmdLet gets a Driver Package Definition.

    .NOTES

    #>
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param (
        # Specifies the name and path to the Driver Package Definition file.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.txt')})]
        [Alias("FullName")]
        [string]$Path
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start getting Driver Package Definition from '$Path'."
    }

    process {
        Write-Verbose "  Getting Driver Package Definition from '$Path'."

        Read-DefinitionFile -Path $Path
    }
    end{
        Write-Verbose "Finished getting Driver Package Definition."
    }
}