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
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Read driver package definition file ('Path':'$Path')")

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
                $Definition[$section][$Matches[1]] = $Matches[2]
                $script:Logger.Trace("Reading key: $($Matches[1]), value $($Matches[2])")
            }

            "^((;|#).*)$|^((?!=|\[|\]).)+$" {
                # Comment
                if (-not($Section)) {
                    $Section = "Blank"
                    $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                }
                $CommentCount = $CommentCount + 1
                $Name = "Comment_" + $CommentCount
                $Definition[$Section][$Name] = $Matches[1]
                if (-not([string]::IsNullOrEmpty($Matches[1]))) {
                    $script:Logger.Trace("Reading comment: $($Matches[1])")
                }
            }
        }

        if ($Definition.Keys -contains 'OSDrivers') {
            # Ensure mandatory fields are set
            $SaveChanges = $false
            if ($Definition['OSDrivers'].Keys -notcontains 'ID') {
                $Definition['OSDrivers']['ID'] = [guid]::NewGuid().ToString()
                $script:Logger.Debug("Driver package definition file is missing 'ID' property. Creating new ID '$($Definition['OSDrivers']['ID'])'.")
                $SaveChanges = $true
            }

            if ($SaveChanges) {
                $script:Logger.Debug("Saving changes to driver package definition.")
                Write-DefinitionFile -Definition $Definition -Path $Path
            }

            $Definition
        } else {
            $script:Logger.Error("No valid driver package definition file. Missing 'OSDrivers' section in file '$Path'.")
        }
    }
}