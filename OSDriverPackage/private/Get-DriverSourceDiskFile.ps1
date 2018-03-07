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
        # Add inf file itself to the list of SourceDiskFiless
        $SourceDiskFiles += (Split-Path -Path $Path -Leaf)

        # Evaluate inf file
        # Get content of Strings, SourceDisksNames and SourceDisksFiles sections
        # Order of sections is not defined. Read them all first.
        $Strings = @{}
        $Disks = [ordered]@{}
        $Files = [ordered]@{}
        switch -Regex (Get-Content $Path) {
            "; set SIGNING_KEY_VERSION"  {
                # if it exists, it should be at the very end of an inf file
                # Some inf files have some rubbish after this which could cause problems
                # TODO: Check if this line also shows up in the middle of an inf file
                Write-Verbose "Stop parsing inf file due to '; set SIGNING_KEY_VERSION' line."
                break
            }
            "^\[(.+)\]$"  {
                # Section
                $Section = $Matches[1]
                Write-Verbose "Section: $Section"
            }
            "^(?!;|#)(.+?)\s*=\s*(.*)" {
                # Key
                if ($Section -eq 'Version' ) {
                    # Get catalog file
                    if ($Matches[1] -like 'CatalogFile*') {
                        $SourceDiskFiles += $Matches[2] -replace ';(.+)' ,''
                        Write-Verbose "Catalog file found: '$($Matches[2])'."
                    }
                } elseif ($Section -eq 'Strings') {
                    # Folder names can contain variables
                    # Keep list of all defined strings
                    # Clean up Variable value
                    $Value = $Matches[2] -replace ';(.+)' ,''
                    $Value = $Value.Trim().Trim('"')
                    $Strings[$Matches[1]] = $Value.Trim()
                    Write-Verbose "Variable found: $($Matches[1]) = $Value"
                } elseif ($Section -like 'SourceDisksNames*') {
                    Write-Verbose "SourceDisk found: $_"
                    $Disks[$Matches[1]] = $Matches[2] -replace ';(.+)' ,''
                } elseif ($Section -like 'SourceDisksFiles*') {
                    Write-Verbose "SourceFile found: $_"
                    $Files[$Matches[1]] = $Matches[2] -replace ';(.+)' ,''
                }
            }
        }

        # Resolve 'SourceDisksNames' values first if necessary
        if ($Disks.Count -gt 0) {
            Write-Verbose "Processing SourceDisks ..."
            foreach ($Disk in @($Disks.Keys)) {
                $Values = (($Disks["$Disk"]) -split ',')
                $DiskName = ''
                if ($Values.Count -eq 4) {
                    if ([string]::IsNullOrEmpty($Values[3])) {
                        # empty string. Use Root folder
                        # e.g. 1 = %DiskID%,,,
                        $Disks["$Disk"] = ''
                    } else {
                        # subfolder defined. Resolve if necessary
                        # e.g. 1 = %DiskID%,"Filename",,\subfolder
                        $DiskName = ($Values[3])
                        if ($DiskName -match '%(.+?)%') {
                            #Pathname contains a variable. Resolve
                            $VarName = $Matches[1]
                            if (-Not([string]::IsNullOrEmpty($VarName))) {
                                if ($Strings.ContainsKey($VarName)){
                                    $DiskName = $DiskName -replace '',"$($Strings[$VarName])"
                                } else {
                                    Write-Verbose "Unable to resolve '$($Matches[1])' of SourceDisksName '$($Disks["$Disk"])'."
                                }
                            }
                        }
                    }
                } else {
                    # ignore all other cases and assume it's in the root
                    # TODO: Validate proper behaviour
                    $DiskName = ''
                }

                # Fix '\\' in path name
                $DiskName = $DiskName.Trim() -replace '\\\\', '\'
                # Remove any '"'
                $DiskName = $DiskName.Trim() -replace '"', ''
                # remove facing and trailing '\'
                $Diskname = $Diskname.Trim('\')
                $Disks["$Disk"] = $DiskName
                Write-Verbose "SourceDisk: $Disk = $Diskname"
            }
        }

        # now get proper SourceDisksFiles including path
        if ($Files.Count -gt 0) {
            foreach ($File in @($Files.Keys)) {
                $Values = $Files["$File"] -split ','
                $Filepath = $Disks["$($Values[0])"]
                if ($Values.Count -gt 1) {
                    # possible subfolder specified
                    $Subfolder = ''
                    if (-Not([string]::IsNullOrEmpty($Values[1]))) {
                        Write-Verbose "Subfolder specified $($Values[1])"
                        # subfolder specified
                        # e.g. Driver.cur	= 1,%Cursor_DataPath%
                        if ($Values[1] -match '%(.+?)%') {
                            Write-Verbose "Subfolder contains variable."
                            # subfolder contains a variable. Resolve
                            $VarName = $Matches[1]
                            Write-Verbose "Variable name : $VarName"
                            if (-Not([string]::IsNullOrEmpty($VarName))) {
                                if ($Strings.ContainsKey($VarName)){
                                    $Subfolder = $Values[1] -replace '%(.+?)%',"$($Strings[$VarName])"
                                    Write-Verbose "Epxand to '$Subfolder'"
                                } else {
                                    Write-Verbose "Unable to resolve '$($Matches[1])' of SourceDisksFiles '$($Files["$File"])'."
                                    $Subfolder = $Values[1]
                                }
                            } else {
                                # use as it is
                                $Subfolder = ''
                            }
                        } else {
                            # Use specified path
                            $Subfolder = $Values[1]
                        }
                    }

                    # Fix '\\' in subfolder
                    $Subfolder = $Subfolder.Trim() -replace '\\\\', '\'
                    # Remove any '"'
                    $Subfolder = $Subfolder.Trim() -replace '"', ''
                    # remove facing and trailing '\'
                    $Subfolder = $Subfolder.Trim('\')
                }

                if (-Not([string]::IsNullOrEmpty($Subfolder))) {
                    $Filepath = (("$FilePath\$Subfolder") -replace '"','').Trim('\')
                }

                if ([string]::IsNullOrEmpty($Filepath)) {
                    $SourceDiskFiles += $File
                    Write-Verbose "SourceDiskFile: $File"
                } else {
                    $SourceDiskFiles += "$FilePath\$File"
                    Write-Verbose "SourceDiskFile: $FilePath\$File"
                }
            }
        }

        $SourceDiskFiles
    }
    end {
        Write-Verbose "Finished reading Driver File."
    }
}