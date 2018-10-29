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
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.def')})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Get driver package definition ('Path':'$Path')")
        $script:Logger.Info("Get driver package definition '$Path'.")

        Read-DefinitionFile -Path $Path
    }
}