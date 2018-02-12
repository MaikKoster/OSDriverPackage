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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("Path")]
        [string]$FileName
    )

    process {
        Write-Verbose "Start reading Definition File '$Filename'."

        $Definition = [System.Collections.Specialized.OrderedDictionary]@{}
        switch -Regex (Get-Content $FileName) {
            "^\[(.+)\]$"  {
                # Section
                $Section = $Matches[1]
                $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                $CommentCount = 0
                Write-Verbose "  Reading Section: [$Section]"
            }

            "^(?!;|#)(.+?)\s*=\s*(.*)" {
                # Key
                if (-not($Section)) {
                    $Section = "Blank"
                    $Definition[$Section] = [System.Collections.Specialized.OrderedDictionary]@{}
                }
                $Definition[$section][$Matches[1]] = $Matches[2]
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
            }
        }

        if ($Definition.Keys -contains 'OSDrivers') {
            $Definition
        } else {
            Write-Verbose "No valid Definition file. Missing 'OSDrivers' section in file '$Filename'."
        }

        Write-Verbose "Finished reading Definition File."
    }
}