function Get-OSDriverCompatibleID {
    [CmdLetBinding()]
    [Outputtype([string])]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$HardwareID
    )

    process {
        $script:Logger.Trace("Get compatible ID ('HardwareID':'$HardwareID')")

        $Identifier = $HardwareID.Split('\')
        $Bus = $Identifier[0]
        if ($Bus -eq 'PCI') {
            # PCI devices
            # Taken from https://docs.microsoft.com/en-us/windows-hardware/drivers/install/identifiers-for-pci-devices
            # Standard Formats for PCI Devices.
            # PCI\VEN_v(4)&DEV_d(4)&SUBSYS_s(4)n(4)&REV_r(2)
            # PCI\VEN_v(4)&DEV_d(4)&SUBSYS_s(4)n(4)
            # PCI\VEN_v(4)&DEV_d(4)&REV_r(2)
            # PCI\VEN_v(4)&DEV_d(4)
            #
            # Compatible formats generated by the PCI bus driver
            # PCI\VEN_v(4)&DEV_d(4)&REV_r(2)
            # PCI\VEN_v(4)&DEV_d(4)
            #
            # Generate list of compatible formats based on above

            # Try to identify components
            $Components = $Identifier[1].Split('&')
            foreach ($Component In $Components) {
                if ($Component -like 'VEN_*') {
                    $Vendor = $Component
                } elseif ($Component -like 'DEV_*') {
                    $Device = $Component
                } elseif ($Component -like 'SUBSYS_*') {
                    $Subsystem = $Component
                } elseif ($Component -like 'REV_*') {
                    $Revision = $Component
                } elseif ($Component -like 'CC_*') {
                    $ClassCode = $Component
                } else {
                    $script:Logger.Warn("Unable to identify Device component '$Component' from HardwareID '$HardwareID'.")
                }
            }

            if (-Not([string]::IsNullOrEmpty($Vendor))) {
                if (-Not([string]::IsNullOrEmpty($Device))) {
                    "$Bus\$Vendor&$Device"
                    $script:Logger.Trace("Compatible ID: $Bus\$Vendor&$Device")
                    if (-Not([string]::IsNullOrEmpty($Revision))) {
                        "$Bus\$Vendor&$Device&$Revision"
                        $script:Logger.Trace("Compatible ID: $Bus\$Vendor&$Device&$Revision")
                        # if (-Not([string]::IsNullOrEmpty($Subsystem))) {
                        #     "PCI\$Vendor&$Device&$Subsystem&$Revision"
                        # }
                    }
                    if (-Not([string]::IsNullOrEmpty($Subsystem))) {
                        "$Bus\$Vendor&$Device&$Subsystem"
                        $script:Logger.Trace("Compatible ID: $Bus\$Vendor&$Device&$Subsystem")
                    }
                }
            }

        } elseif ($Bus -eq 'USB') {
            # Standard USB Identifiers - https://docs.microsoft.com/en-us/windows-hardware/drivers/install/standard-usb-identifiers
            # Single interface devices
            # USB\VID_v(4)&PID_d(4)&REV_r(4)
            #
            # USB\VID_v(4)&PID_d(4)
            # USB\CLASS_c(2)&SUBCLASS_s(2)&PROT_p(2)
            # USB\CLASS_c(2)&SUBCLASS_s(2)
            # USB\CLASS_c(2)
            #
            # Multi interface devices
            # USB\VID_v(4)&PID_d(4)&MI_z(2)#
            # USB\CLASS_d(2)&SUBCLASS_s(2)&PROT_p(2)
            # USB\CLASS_d(2)&SUBCLASS_s(2)
            # USB\CLASS_d(2)
            # USB\COMPOSITE
            #
            # Try to identify components
            $Components = $Identifier[1].Split('&')
            foreach ($Component In $Components) {
                if ($Component -like 'VID_*') {
                    $Vendor = $Component
                } elseif ($Component -like 'PID_*') {
                    $Product = $Component
                } elseif ($Component -like 'REV_*') {
                    $Revision = $Component
                } elseif ($Component -like 'MI_*') {
                    $Interface = $Component
                } else {
                    $script:Logger.Warn("Unable to identify Device component '$Component' from HardwareID '$HardwareID'.")
                }
            }

            if (-Not([string]::IsNullOrEmpty($Vendor))) {
                if (-Not([string]::IsNullOrEmpty($Product))) {
                    "$Bus\$Vendor&$Product"
                    $script:Logger.Trace("Compatible ID: $Bus\$Vendor&$Product")
                }
            }
        } elseif ($Bus -in 'INTELAUDIO','HDAUDIO') {
            #INTELAUDIO\FUNC_d(2)&VEN_v(4)&DEV_d(4)
            #HDAUDIO\FUNC_d(2)&VEN_v(4)&DEV_d(4)

            $Components = $Identifier[1].Split('&')
            foreach ($Component In $Components) {
                if ($Component -like 'FUNC_*') {
                    $Func = $Component
                } elseif ($Component -like 'VEN_*') {
                    $Vendor = $Component
                } elseif ($Component -like 'DEV_*') {
                    $Device = $Component
                } elseif ($Component -like 'SUBSYS_*') {
                    $Subsystem = $Component
                } elseif ($Component -like 'REV_*') {
                    $Revision = $Component
                } else {
                    $script:Logger.Warn("Unable to identify Device component '$Component' from HardwareID '$HardwareID'.")
                }
            }

            if (-Not([string]::IsNullOrEmpty($Func))) {
                if (-Not([string]::IsNullOrEmpty($Vendor))) {
                    if (-Not([string]::IsNullOrEmpty($Device))) {
                        "$Bus\$Func&$Vendor&$Device"
                        $script:Logger.Trace("Compatible ID: $Bus\$Func&$Vendor&$Device")
                        if (-Not([string]::IsNullOrEmpty($Revision))) {
                            "$Bus\$Func&$Vendor&$Device&$Revision"
                            $script:Logger.Trace("Compatible ID: $Bus\$Func&$Vendor&$Device&$Revision")
                        }
                    }
                }
            }

        } elseif ($Bus -eq 'HID') {
            #TODO: Evalute HID structure

        } elseif ($Bus -eq 'ACPI') {
            # Nothing to do here
        } elseif ($Bus -eq 'PSMP') {
            # Nothing to do here
        } elseif ($Bus -eq 'PTL') {
            # Nothing to do here
        } elseif ($Bus -eq 'root') {
            # Nothing to do here
        } elseif ($Bus -eq 'SNXPCARD_ENUM') {
            # Nothing to do here
        } elseif ($Bus -like '{*}') {
            # Nothing to do here
        } else {
            $script:Logger.Warn("Unknown Bus type '$Bus' from HardwareID '$HardwareID'")
        }

        #Always return the input object
        $HardwareID
    }
}