function Get-DriverSourceDiskFile {
    <#
    .Synopsis
        Gets the Source Disk File(s) from the supplied Driver.

    .Description
        Gets the Source Disk File(s) from the supplied Driver..

    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        # Specifies the name and path to the Driver file (inf).
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
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
        Write-Verbose "Start reading Driver File."
    }

    process {
        Write-Verbose "  Reading Driver File '$Path'."

        $SourceDiskFiles = [string[]]@()
        # Add inf and cat file to the list of SourceDiskFiless
        $SourceDiskFiles += (Split-Path -Path $Path -Leaf)
        switch -Regex (Get-Content $Path) {
            "^\[(.+)\]$"  {
                # Section
                $Section = $Matches[1]
                if ($Section -eq 'SourceDisksFiles') {
                    Write-Verbose "    Reading Section: [$Section]"
                    $Found = $true
                }
            }

            "^(?!;|#)(.+?)\s*=\s*(.*)" {
                # Key
                if ($Section -eq 'Version') {
                    if ($Matches[1] -eq 'CatalogFile') {
                        $SourceDiskFiles += $Matches[2]
                    }
                }
                if ($Found) {
                    if ($Section -eq 'SourceDisksFiles') {
                        Write-Verbose "    $($Matches[1])"
                        $SourceDiskFiles += $Matches[1]
                    } else {
                        Break
                    }
                }
            }
        }

        $SourceDiskFiles
    }
    end {
        Write-Verbose "Finished reading Driver File."
    }
}