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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path
    )
    begin {
        Write-Verbose "Start reading Definition File."
    }
    process {
        Write-Verbose "  Reading Definition File '$Path'."

        $Definition = [System.Collections.Specialized.OrderedDictionary]@{}
        switch -Regex (Get-Content $Path) {
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
            Write-Verbose "  No valid Definition file. Missing 'OSDrivers' section in file '$Path'."
        }
    }
    end {
        Write-Verbose "Finished reading Definition File."
    }
}