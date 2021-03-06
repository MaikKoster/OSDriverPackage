function Read-DefinitionFile {
    <#
    .Synopsis
        Reads a Driver Package definition file.

    .Description
        Reads the content of a Driver Package definition file into a hashtable.

    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        # Specifies the name and path to the Driver Package Definition file.
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.def')})]
        [Alias("DefinitionFile")]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Read driver package definition file ('Path':'$Path')")

        # First line must be [OSDriverPackage]!!!
        try {
            $FirstLine = Get-Content -Path $Path -First 1 -ErrorAction SilentlyContinue
        } catch {}

        if ([string]::IsNullOrEmpty($FirstLine) -or ($Firstline -ne "[OSDriverPackage]")) {
            $script:Logger.Error("No valid driver package definition file. Missing 'OSDriverPackage' section in file '$Path'.")

        } else {

            $Definition = [System.Collections.Specialized.OrderedDictionary]@{}
            switch -Regex (Get-Content $Path) {
                "^\[(.+)\]$"  {
                    # Section
                    $Section = $Matches[1]
                    $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                    $CommentCount = 0
                    $script:Logger.Trace("Reading section: [$Section]")
                }

                "^(?!;|#)(.+?)\s*=\s*(.*)" {
                    # Key
                    if (-not($Section)) {
                        $Section = "Blank"
                        $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                    }
                    if (-not([string]::IsNullOrEmpty($Matches[1]))) {
                        $Definition[$section][$Matches[1]] = $Matches[2]
                        $script:Logger.Trace("Reading key: $($Matches[1]), value $($Matches[2])")
                    }
                }

                "^((;|#).*)$|^((?!=|\[|\]).)+$" {
                    # Comment
                    if (-not($Section)) {
                        $Section = "Blank"
                        $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                    }
                    $CommentCount = $CommentCount + 1
                    $Name = "Comment_" + $CommentCount
                    if (-not([string]::IsNullOrEmpty($Matches[1]))) {
                        $Definition[$Section][$Name] = $Matches[1]
                        $script:Logger.Trace("Reading comment: $($Matches[1])")
                    }
                }
            }

            if ($Definition.Keys -contains 'OSDriverPackage') {
                # Ensure mandatory fields are set
                $SaveChanges = $false
                if ($Definition['OSDriverPackage'].Keys -notcontains 'ID') {
                    $Definition['OSDriverPackage']['ID'] = [guid]::NewGuid().ToString()
                    $script:Logger.Debug("Driver package definition file is missing 'ID' property. Creating new ID '$($Definition['OSDriverPackage']['ID'])'.")
                    $SaveChanges = $true
                }

                if ($SaveChanges) {
                    $script:Logger.Debug("Saving changes to driver package definition.")
                    Write-DefinitionFile -Definition $Definition -Path $Path
                }

                $Definition
            } else {
                $script:Logger.Error("No valid driver package definition file. Missing 'OSDriverPackage' section in file '$Path'.")
            }
        }
    }
}