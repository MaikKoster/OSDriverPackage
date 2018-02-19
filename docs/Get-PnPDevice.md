---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Get-PnPDevice

## SYNOPSIS
Returns a list of all registered PnP Devices.

## SYNTAX

```
Get-PnPDevice [[-ComputerName] <String>] [-HardwareIDOnly] [<CommonParameters>]
```

## DESCRIPTION
Returns detailed information about the registered PnP Devices on the specified computer.
Uses WMI to query the information.
Useful to collect a list of "critical" HardwareIDs to be used when comparing Drivers.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ComputerName
Specifies the the name of the computer

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -HardwareIDOnly
Specifies, if only a list of HardwareIDs should be returned.
Usefull to directly pass the output to 'Compare-OSDriver' or 'Compare-OSDriverPackage'

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
