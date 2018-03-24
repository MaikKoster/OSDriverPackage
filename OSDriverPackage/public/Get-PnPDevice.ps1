function Get-PnPDevice {
    <#
    .SYNOPSIS
        Returns a list of all registered PnP Devices.

    .DESCRIPTION
        Returns detailed information about the registered PnP Devices on the specified computer.
        Uses WMI to query the information.
        Useful to collect a list of "critical" HardwareIDs to be used when comparing Drivers.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Specifies the the name of the computer
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ComputerName,

        # Specifies, if only a list of HardwareIDs should be returned.
        # Usefull to directly pass the output to 'Compare-OSDriver' or 'Compare-OSDriverPackage'
        [switch]$HardwareIDOnly
    )

    process{
        $script:Logger.Trace("Get PnP devices ('ComputerName':'$ComputerName', 'HardwareIDOnly':'$HardwareIDOnly'")

        $Props = @{
            ClassName = "Win32_PnPEntity"
        }

        if (-Not([string]::IsNullOrEmpty($ComputerName))){
            $script:Logger.Info("Processing '$Computer'")
            $Props.ComputerName = $ComputerName
        }

        $PnPEntities = Get-CimInstance  @Props

        if ($HardwareIDOnly.IsPresent) {
            $PnPEntities | Select-Object -ExpandProperty HardwareID
        } else {
            $PnPEntities
        }
    }
}