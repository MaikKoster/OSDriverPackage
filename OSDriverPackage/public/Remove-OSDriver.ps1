function Remove-OSDriver {
    <#
    .SYNOPSIS
        Removes a Driver file.

    .DESCRIPTION
        Removes the specified Driver file, including all referenced Driver source files.
        All other inf files in the same folder will be checked, if they are crossreferencing
        any of those files. Only files without any additional reference will be removed.
        If there are no inf files left in the folder after the removal, all other files will
        be removed as well. Subfolders will not be touched.
        If the folder is empty at the end, the folder will be removed as well.

    .NOTES
        Only supports inf files that reference files in the same folder. All references to
        subfolders are ignored.

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specifies the name and path for the driver file
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
        Write-Verbose "Start removing Driver."
    }

    process {
        Write-Verbose " Processing path '$Path'."

        # Get Driver information
        $DriverInfo = Get-OSDriver -Path $Path
        $DriverFileName = Split-Path -Path $Path -Leaf
        $ParentPath = Split-Path -Path $Path -Parent

        if ($null -ne $DriverInfo) {
            # Get the related files of all other drivers in the same folder
            $ReferencedFiles = Get-ChildItem -Path $ParentPath -Filter '*.inf' |
                                Where-Object {$_.Name -ne $DriverFileName} |
                                Foreach-Object {Get-DriverSourceDiskFile -Path $_.FullName -Verbose:$false }|
                                Select-Object -Unique

            foreach ($DriverSourceFile in $DriverInfo.SourceFiles) {
                if ($ReferencedFiles -notcontains $DriverSourceFile) {
                    if ($PSCmdlet.ShouldProcess("Removing driver source file '$DriverSourceFile'.")) {
                        Write-Verbose "  Removing driver source file '$DriverSourceFile'."
                        Remove-Item -Path (Join-Path -Path $ParentPath -ChildPath $DriverSourceFile) -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    Write-Verbose " Can't remove '$DriverSourceFile'. It is still referenced by another Driver."
                }
            }

            # Assuming that all drivers are being installed via inf files, we
            # remove all additional files if no driver is left in the folder.
            # Sometimes not all files are referenced in the inf and some stuff is left.
            # We can't take care about subfolder though.
            if ((Get-ChildItem -Path $ParentPath -Filter '*.inf').Count -eq 0) {
                Write-Verbose "  Removing leftover files in '$ParentPath'."
                # Also clean up subfolders, if there are no inf files present
                if ((Get-ChildItem -Path $ParentPath -Filter '*.inf' -Recurse).Count -eq 0) {
                    Get-ChildItem -Path $ParentPath | Remove-Item -Force -Recurse
                } else {
                    Get-ChildItem -Path $ParentPath -File | Remove-Item -Force
                }
            }

            # Remove the folder if there aren't any files left
            if ((Get-ChildItem -Path $ParentPath -Recurse).Count -eq 0) {
                $GrandParent = (Get-Item $ParentPath).Parent.FullName
                if ($PSCmdlet.ShouldProcess("Removing empty folder '$ParentPath'.")) {
                    Write-Verbose "  Removing empty folder '$ParentPath'."
                    Remove-Item -Path $ParentPath -Force
                }

                # Try to clean up next level parent folder
                # Assumption: if there are no inf or cab files in the parent or any subfolders,
                # it's safe to remove as well.
                # TODO: Validate if we are not removing needed files
                # TODO: Create recursive function if another level seems necessary
                if ((Get-ChildItem -Path $GrandParent -include '*.inf', '*.cab' -Recurse).Count -eq 0) {
                    if ($PSCmdlet.ShouldProcess("Removing folder '$GrandParent'.")) {
                        Write-Verbose "  Removing folder '$GrandParent'."
                        Remove-Item -Path $GrandParent -Force -Recurse
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "Finished removing Driver."
    }
}