function Get-OSDriver {
    <#
    .SYNOPSIS
        Returns information about the specified driver.

    .DESCRIPTION
        Returns information about the specified driver and the related files.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Specifies the name and path for the driver file
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -match '\.(inf|json)')})]
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
        Write-Verbose "Start getting Windows Driver info."
    }

    process {
        $Driver = Get-Item $Path
        if ($Driver.Name -eq 'autorun.inf') {
            Write-Verbose "  Skipping '$Path'."
        } elseif ($Driver.Extension -eq '.inf') {
            Write-Verbose "  Getting Windows Driver info from '$Path'"

            #TODO: Get-WindowsDriver requires elevation! Might need to be replaced. Not sure if it's worth the effort
            # Get Windows Drivers info using Dism.
            # Extract relevant information only to save space.
            $DriverInfo = Get-WindowsDriver -Online -Driver $Path
            if ($null -ne $DriverInfo) {
                $First = $DriverInfo | Select-Object -First 1

                # Get SourceDiskFiles
                # Remove duplicates
                $DriverSourceFiles = Get-DriverSourceDiskFile -Path $Path.ToString() -Verbose:$false | Group-Object  HardwareID, Architecture | ForEach-Object {$_.Group | Select-Object -First 1} | Sort-Object HardwareID
                [PSCustomObject]@{
                    DriverFile = $Path #($DriverFile.FullName)
                    ClassName = ($First.ClassName)
                    ClassGuid = ($First.ClassGuid)
                    ProviderName = ($First.ProviderName)
                    ManufacturerName = ($First.ManufacturerName)
                    Version = ($First.Version)
                    Date = ($First.Date)
                    SourceFiles = $DriverSourceFiles
                    HardwareIDs = @($DriverInfo  | ForEach-Object {
                        $HardwareID = [PSCustomObject]@{
                            HardwareID = ($_.HardwareId)
                            HardwareDescription = ($_.HardwareDescription)
                            Architecture = ''
                        }
                        if ($_.Architecture -eq 0) {
                            $HardwareID.Architecture = 'x86'
                        } elseif ($_.Architecture -eq 9) {
                            $HardwareID.Architecture = 'x64'
                        } elseif ($_.Architecture -eq 6) {
                            $HardwareID.Architecture = 'ia64'
                        }
                        $HardwareID
                    })
                }
            }
        } elseif ($Driver.Extension -eq '.json') {
            Read-PackageInfoFile -Path ($Driver.FullName)
        }
    }

    end {
        Write-Verbose "Finished reading Windows Driver info."
    }

}