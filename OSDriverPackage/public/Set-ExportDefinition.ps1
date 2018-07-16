function Set-ExportDefinition {
    <#
    .SYNOPSIS
        Updates the specified Export Definition

    .DESCRIPTION

    .NOTES

    #>

    [OutputType([object[]])]
    param(
        # Specifies the root path of the Driver source folder
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_)})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the Export definition
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object]$ExportDefinition
    )

    begin {
        $ExportDefinitionFilename = 'DriverPackageExports.json'
        $ExportDefinitionFullname = Join-Path -Path $Path -ChildPath $ExportDefinitionFilename
    }

    process {
        $script:Logger.Trace("Set driver package export definition ('Path':'$Path')")

        Write-ExportDefinitionFile -Definitions $ExportDefinition -Path $ExportDefinitionFullname
    }
}