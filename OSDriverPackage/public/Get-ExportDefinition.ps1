function Get-ExportDefinition {
    <#
    .SYNOPSIS
        Returns the Export Definitions

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

        # Specifies the name of the export configuration to get
        [string]$Name
    )

    begin {
        $ExportDefinitionFilename = 'DriverPackageExports.json'
        $ExportDefinitionFullname = Join-Path -Path $Path -ChildPath $ExportDefinitionFilename
    }

    process {
        $script:Logger.Trace("Get driver package export definition ('Path':'$Path')")

        if (-Not(Test-Path -Path $ExportDefinitionFullname)) {
            [System.Collections.ArrayList]$ExportDefinitions = @()
        } else {
            $ExportDefinitions = @(Read-ExportDefinitionFile -Path $ExportDefinitionFullname)
        }

        if (-Not([string]::IsNullOrEmpty($Name))) {
            $ExportDefinitions | Where-Object {$_.Name -eq "$Name"}
        } else {
            $ExportDefinitions
        }

    }
}