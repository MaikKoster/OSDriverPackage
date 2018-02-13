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
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq '.inf')})]
        [Alias("Path")]
        [string]$Filename
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    process {
        Write-Verbose "Start removing Driver '$Filename'."

        # Get Driver information
        $DriverInfo = Get-OSDriver -Filename $Filename
        $DriverFileName = Split-Path -Path $Filename -Leaf
        $ParentPath = Split-Path -Path $Filename -Parent

        if ($null -ne $DriverInfo) {
            # Get the related files of all other drivers in the same folder
            $ReferencedFiles = Get-ChildItem -Path $ParentPath -Filter '*.inf' |
                                Where-Object {$_.Name -ne $DriverFileName} |
                                Foreach-Object {Get-DriverSourceDiskFile -FileName $_.FullName} |
                                Select-Object -Unique

            foreach ($DriverSourceFile in $DriverInfo.DriverSourceFiles) {
                if ($ReferencedFiles -notcontains $DriverSourceFile) {
                    if ($PSCmdlet.ShouldProcess("Removing driver source file '$DriverSourceFile'.")) {
                        Write-Verbose "  Removing driver source file '$DriverSourceFile'."
                        Remove-Item -Path (Join-Path -Path $ParentPath -ChildPath $DriverSourceFile) -Force
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
                Get-ChildItem -Path $ParentPath -File | Remove-Item -Force
            }

            # Remove the folder if there aren't any files left
            if ((Get-ChildItem -Path $ParentPath -Recurse).Count -eq 0) {
                if ($PSCmdlet.ShouldProcess("Removing empty folder '$ParentPath'.")) {
                    Write-Verbose "  Removing empty folder '$ParentPath'."
                    Remove-Item -Path $ParentPath -Force
                }
            }
        }

        Write-Verbose "Finished removing Driver."
    }

}