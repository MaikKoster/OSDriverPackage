---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Compare-OSDriver

## SYNOPSIS
Checks if the supplied Driver can be replaced by the supplied Core Driver.

## SYNTAX

```
Compare-OSDriver [-CoreDriver] <PSObject> [-Driver] <PSObject> [-CriticalIDs <String[]>]
 [-IgnoreIDs <String[]>] [-PackageHardwareIDs <PSObject[]>] [-IgnoreVersion] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
The Compare-OSDriver CmdLet compares two drivers.
The supplied driver will be evaluated
against the supplied Core Driver.

If it has the same or lower version as the Core Driver, and all Hardware IDs are handled by the Core
Driver as well, the function, it will return $true to indicate, that it can most likely be
replaced by the Core Driver.
If not, it will return $false.

If PassThru is supplied, additional information about the evaluation will be added to the Package
Driver object and passed thru for further actions.
The new poperties will be:
Replace: will be set to $true, if the Driver can be safely replaced by the Core Driver.
$False if not.
LowerVersion: will be set to $true, if the Core Driver has a higher version.
$false, if not.
MissingHardwareIDs: List of Hardware IDs, that are not referenced by the Core Driver.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -CoreDriver
Specifies the Core Driver.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Driver
Specifies the driver that should be compared

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: PackageDriver

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CriticalIDs
Specifies a list of critical PnP IDs, that must be covered by the Core Drivers
if found within the Package Driver.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreIDs
Specifies a list of PnP IDs, that can be safely ignored during the comparison.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PackageHardwareIDs
Specifies a list of HardwareIDs from the Driver Package that contains the supplied Driver.
Some vendors create 'merged' drivers based on individual drivers from the original manufacturer.
As those 'merged' drivers whould always be missing Hardware IDs, as they were orignally supplied
by different, individual drivers, all Drivers within a Driver Package should be seen as an entity.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreVersion
Specifies, if the Driver version should be ignored.

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

### -PassThru
Specifies, if the Package Driver should be returned.
Helpful if used within a pipeline.

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

### System.Boolean

## NOTES

## RELATED LINKS
