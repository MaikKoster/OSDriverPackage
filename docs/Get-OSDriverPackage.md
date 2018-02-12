---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Get-OSDriverPackage

## SYNOPSIS
Gets a Driver Package.

## SYNTAX

```
Get-OSDriverPackage [-Path] <String> [[-Name] <String[]>] [[-Tag] <String[]>] [[-OSVersion] <String[]>]
 [[-Make] <String[]>] [[-Model] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The Get-OSDriverPackage CmdLet get one or multiple Driver Packages based on the supplied conditions.
All supplied conditions are handled as AND.
If no condition is supplied, it is handled as wildcard and
includeds all.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
Specifies the path to the Driver Package.
If a folder is specified, all Driver Packages within that folder and subfolders
will be returned, based on the additional conditions

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Filters the Driver Packages by Name
Wildcards are allowed e.g.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
Filters the Driver Packages by a generic tag.
Can be used to .e.g identify specific Core Packages

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSVersion
Filters the Driver Packages by OSVersion
Recommended to use tags as e.g.
Win10-x64, Win7-x86.
Wildcards are allowed e.g.
Win*-x64

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Make
Filters the Driver Packages by Make(s)/Vendor(s)/Manufacture(s).
Use values from Manufacturer property from Win32_ComputerSystem.
Wildcards are allowed e.g.
*Dell*

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Model
Filters the Driver Packages by Model(s)
Use values from Model property from Win32_ComputerSystem.
Wildcards are allowed e.g.
*Latitude*

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
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
