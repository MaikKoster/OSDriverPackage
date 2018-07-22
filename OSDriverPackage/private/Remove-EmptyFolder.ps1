function Remove-EmptyFolder {
    <#
    .SYNOPSIS
        Removes all empty folders.

    .DESCRIPTION
        Using tail recursion approach to remove all empty folders in a given path.
        Will also remove the supplied path if empty after all iterations.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path of folder that shall be processed.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Removing empty folders ('Path':'$Path'")
        foreach ($ChildDirectory in Get-ChildItem -Force -LiteralPath $Path -Directory) {
            Remove-EmptyFolder -Path $ChildDirectory.FullName
        }

        $CurrentChildren = Get-ChildItem -Force -LiteralPath $Path
        if ($null -eq $currentChildren) {
            $script:Logger.Debug("Removing empty folder '$Path'.")
            Remove-Item -Force -LiteralPath $Path
        }
    }
}