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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
        [Alias("Path")]
        [string]$FileName
    )

    process {
        Write-Verbose "Start reading Driver File '$Filename'."

        $SourceDiskFiles = [string[]]@()
        # Add inf and cat file to the list of SourceDiskFiless
        $SourceDiskFiles += (Split-Path -Path $FileName -Leaf)
        switch -Regex (Get-Content $FileName) {
            "^\[(.+)\]$"  {
                # Section
                $Section = $Matches[1]
                if ($Section -eq 'SourceDisksFiles') {
                    Write-Verbose "  Reading Section: [$Section]"
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
                        Write-Verbose "  $($Matches[1])"
                        $SourceDiskFiles += $Matches[1]
                    } else {
                        Break
                    }
                }
            }
        }

        $SourceDiskFiles

        Write-Verbose "Finished reading Driver File."
    }
}