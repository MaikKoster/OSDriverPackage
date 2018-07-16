---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# New-ExportDefinition

## SYNOPSIS
Creates a new Export Definition

## SYNTAX

```
New-ExportDefinition [-Name] <String> -SourceRoot <String> -TargetRoot <String> [-Description <String>]
 [-DriverPackageName <String[]>] [-Tag <String[]>] [-OSVersion <String[]>] [-Architecture <String[]>]
 [-Make <String[]>] [-Model <String[]>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Name
Specifies the name of the Export definition

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SourceRoot
Specifies the root of the Driver package source

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetRoot
Specifies the root of the Driver Package export path

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
{{Fill Description Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DriverPackageName
Filters the Driver Packages by Name
Wildcards are allowed e.g.
Intel*

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Architecture
Filters the Driver Packages by Architecture
Recommended to use tags as e.g.
x64, x86.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
Position: Named
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
Position: Named
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
