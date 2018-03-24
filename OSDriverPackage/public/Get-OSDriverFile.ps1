function Get-OSDriverFile {
    <#
    .SYNOPSIS
        Finds specified driver files.

    .DESCRIPTION
        Finds specified driver files.
        Optionally all directories containing these files can be removed.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the path where to search for driver files
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the name of the drivers files.
        # The name can include wildcards. Default is '*.inf'
        [string]$Files = '*.inf',

        # Specifies if the Driver Package should be expanded on the fly.
        # On default, expand -D will be used to extract a list of file names only.
        # Only usefull if a Driver Package is specified.
        [switch]$Expand
    )

    process {
        $script:Logger.Trace("Get driver files ('Path':'$Path', 'Files':'$Files', 'Expand':'$Expand'")

        $script:Logger.Info("Get driver files from '$Path'.")
        $DriverPackage = Get-Item -Path $Path
        $DriverFiles = @()
        if ($DriverPackage.PSIsContainer) {
            $DriverFiles = Get-ChildItem -Path $Path -Recurse -File -Filter $Files

        } elseif ($DriverPackage.Extension -eq '.cab') {
            if (Test-Path ($DriverPackage.FullName -replace '.cab', '')) {
                $DriverFiles = Get-ChildItem -Path ($DriverPackage.FullName -replace '.cab', '') -Recurse -File -Filter $Files

            } elseif ($Expand.IsPresent) {
                $script:Logger.Debug('Temporarily expanding content of Driver Package.')
                $ExpandedPath = Expand-OSDriverPackage -Path $Path -Force -PassThru

                $DriverFiles = Get-ChildItem -Path $ExpandedPath -Recurse -File -Filter $Files

                $script:Logger.Debug('Removing temporary content.')
                Remove-Item -Path $ExpandedPath -Recurse -Force
            } else {
                $script:Logger.Debug('Reading files from Driver Package.')
                $Output = EXPAND -D "$Path" -F:"$Files"
                #TODO: get someone with better Regex skills. Need to skip ': ' from the negative lookahead
                switch -Regex ($Output) {
                    "\:(?:.(?!\: ))+$" {
                        $DriverFiles += $($Matches[0]).Trim(':').Trim()
                    }
                }

                #Remove duplicates, as we don't have a path
                $DriverFiles = $DriverFiles | Select-Object -Unique
            }
        }

        $DriverFiles
    }
}