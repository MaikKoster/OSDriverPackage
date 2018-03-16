---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Compare-OSDriverPackage

## SYNOPSIS
Checks the supplied Driver Package against the Core Driver Package.

## SYNTAX

```
Compare-OSDriverPackage [-CoreDriverPackage] <PSObject[]> [-DriverPackage] <PSObject>
 [[-CriticalIDs] <String[]>] [[-IgnoreIDs] <String[]>] [-IgnoreVersion] [[-Mappings] <Hashtable>]
 [[-Architecture] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Compare-OSDriverPackage CmdLet compares Driver Packages.
The supplied Driver Package will be
evaluated against the supplied Core Driver Package.

It uses Compare-OSDriver to compare related Drivers in each Driver Package.
Drivers will be matched
by the name of the inf file.
To compare drivers where a vendor uses different filenames for the same
driver, you can use Compare-OSDrive to overwrite this standard behaviour individuall.

Comparison logic is based on the implementation of Compare-OSDriver:
If it has the same or lower version as the Core Driver, and all Hardware IDs are handled by the Core
Driver as well, the Replace property will be set to $true to indicate, that it can most likely be
replaced by the Core Driver.
If not, it will return $false.

Additional information about the evaluation will be added to each Driver object to allow further
actions.
The new poperties will be:

- Replace: will be set to $true, if the Driver can be safely replaced by the Core Driver.
$False if not.
- LowerVersion: will be set to $true, if the Core Driver has a higher version.
$false, if not.
- MissingHardwareIDs: List of Hardware IDs, that are not referenced by the Core Driver.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -CoreDriverPackage
Specifies the Core Driver.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DriverPackage
Specifies the Driver Package that should be compared

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
Position: 3
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
Position: 4
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

### -Mappings
Specifies a list of known mappings of Driver inf files.
Some computer vendors tend to rename the original inf files as part of their customization process

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -Architecture
Specifies if the Driver Package is targetting a single architecture only or all

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
