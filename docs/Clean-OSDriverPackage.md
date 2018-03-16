---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Clean-OSDriverPackage

## SYNOPSIS
Checks the supplied Driver Package against the Core Driver Package and cleans up all
unneeded Drivers.

## SYNTAX

```
Clean-OSDriverPackage [-CoreDriverPackage] <PSObject[]> [-DriverPackage] <PSObject> [[-CriticalIDs] <String[]>]
 [[-IgnoreIDs] <String[]>] [-IgnoreVersion] [[-Mappings] <Hashtable>] [-KeepFolder] [[-Architecture] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Clean-OSDriverPackage CmdLet compares Driver Packages.
The supplied Driver Package
will be evaluated against the supplied Core Driver Package.

It uses Compare-OSDriverPackage to compare related Drivers in each Driver Package.
See
Compare-OSDriverPackage for more details on the evluation details.

If there are unneeded Drivers, it will temporarily expand the Driver Package, remove all
unneeded Drivers, update the Driver Package info file, and compress the updated content.

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
Accept pipeline input: False
Accept wildcard characters: False
```

### -DriverPackage
Specifies that should be compared

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

### -KeepFolder
Specifies if the temporary content of the expanded folder should be kept.
On default, the content will be removed, after all changes have been applied.
Helpful when running several iterations.

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
