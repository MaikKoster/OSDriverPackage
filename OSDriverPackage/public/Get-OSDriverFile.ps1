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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the name of the drivers files.
        # The name can include wildcards. Default is '*.inf'
        [string]$Files = '*.inf',

        # Specifies if the Parent Directory should be removed.
        [switch]$RemoveDirectories,

        # Specifies if a gridview should be shown to select the driver files.
        [switch]$ShowGrid,

        # Specifies if the Driver Package should be expanded on the fly.
        # On default, expand -D will be used to extract a list of file names only.
        # Only usefull if a Driver Package is specified.
        [switch]$Expand

    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        Write-Verbose "Start getting Driver Files."
    }

    process {
        Write-Verbose "  Getting Driver files from '$Path'."

        $DriverPackage = Get-Item -Path $Path
        $DriverFiles = @()
        if ($DriverPackage.PSIsContainer) {
            $DriverFiles = Get-ChildItem -Path $Path -Recurse -File -Include $Files

            if ($ShowGrid.IsPresent) {
                $DriverFiles = $DriverFiles | Select-Object -Property Directory,Name,Length,FullName,CreationTime | Out-Gridview -Title 'Select INF Files' -PassThru
            }

        } elseif ($DriverPackage.Extension -eq '.cab') {
            if ($Expand.IsPresent) {
                Write-Verbose '    Temporarily expanding content of Driver Package.'
                #$ArchivePath = Join-Path -Path (Split-Path -Path $Path -Parent) -ChildPath ($DriverPackage.BaseName)
                $ExpandedPath = Expand-OSDriverPackage -Path $Path -Force -PassThru
                $ExpandedArchive = $true

                $DriverFiles = Get-ChildItem -Path $ExpandedPath -Recurse -File -Include $Files

                if ($ShowGrid.IsPresent) {
                    $DriverFiles = $DriverFiles | Select-Object -Property Directory,Name,Length,FullName,CreationTime | Out-Gridview -Title 'Select INF Files' -PassThru
                }

            } else {
                Write-Verbose '    Reading files from Driver Package.'
                $Output = EXPAND -D "$Path" -F:"$Files"
                #TODO: get someone with better Regex skills. Need to skip ': ' from the negative lookahead
                switch -Regex ($Output) {
                    "\:(?:.(?!\: ))+$" {
                        $DriverFiles += $($Matches[0]).Trim(':').Trim()
                    }
                }

                #Remove duplicates, as we don't have a path
                $DriverFiles = $DriverFiles | Select-Object -Unique
                if ($ShowGrid.IsPresent) {
                    $DriverFiles = $DriverFiles | Out-Gridview -Title 'Select INF Files' -PassThru
                }
            }
        }

        if ($RemoveDirectories.IsPresent ) {
            foreach ($DriverFile in $DriverFiles) {
                $DriverFolder = $DriverFile.Directory.FullName
                # Folder could have been removed already
                if (Test-Path $DriverFolder){
                    if ($PSCmdlet.ShouldProcess("Removing folder '$DriverFolder'.")) {
                        Write-Verbose "    Removing folder '$DriverFolder'."
                        Remove-Item -Path $DriverFolder -Recurse -Force
                    }
                }
            }

            if ($ExpandedArchive) {
                Write-Verbose "    Compressing Driver Package again."
                Compress-Folder -Path $ExpandedPath -HighCompression -RemoveSource
            }
        } else {
            if ($ExpandedArchive) {
                Write-Verbose "    Removing temporary Driver Package content."
                Remove-Item -Path $ExpandedPath -Recurse -Force
            }

            $DriverFiles
        }
    }
    end {
        Write-Verbose "Finished getting Driver Files."
    }
}