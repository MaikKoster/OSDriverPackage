---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# New-OSDriverPackageDefinition

## SYNOPSIS
Creates a new Driver Package definition file.

## SYNTAX

### PackageWithSettings (Default)
```
New-OSDriverPackageDefinition [-DriverPackagePath] <String> [-Tag <String[]>] [-ExcludeTag <String[]>]
 [-OSVersion <String[]>] [-ExcludeOSVersion <String[]>] [-Architecture <String[]>] [-Make <String[]>]
 [-ExcludeMake <String[]>] [-Model <String[]>] [-ExcludeModel <String[]>] [-URL <String>] [-SkipPNPDetection]
 [-IgnoreSubSys] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### NameWithDefinition
```
New-OSDriverPackageDefinition -FileName <String> -Definition <OrderedDictionary> [-Force] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### NameWithSettings
```
New-OSDriverPackageDefinition -FileName <String> [-Tag <String[]>] [-ExcludeTag <String[]>]
 [-OSVersion <String[]>] [-ExcludeOSVersion <String[]>] [-Architecture <String[]>] [-Make <String[]>]
 [-ExcludeMake <String[]>] [-Model <String[]>] [-ExcludeModel <String[]>] [-URL <String>] [-WQL <String[]>]
 [-PNPIDs <Hashtable>] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new Driver Package definition file.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DriverPackagePath
Specifies the name and path of the Driver Package
The Definition File will be named exactly the same as the Driver Package.

```yaml
Type: String
Parameter Sets: PackageWithSettings
Aliases: Path

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FileName
Specifies the name and path of the Driver Package Definition file

```yaml
Type: String
Parameter Sets: NameWithDefinition, NameWithSettings
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
Specifies generic tag(s) that can be used to further identify the Driver Package.
Can be used to e.g.
identify specific Core Packages.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeTag
Specifies the excluded generic tag(s).
Can be used to e.g.
identify specific Core Packages.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSVersion
Specifies the supported Operating System version(s).
Recommended to use tags as e.g.
Win10-x64, Win7-x86.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeOSVersion
Specifies the excluded Operating System version(s).
Recommended to use tags as e.g.
Win10-x64, Win7-x86.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Architecture
Specifies the supported Architectures.
Recommended to use the tags x86, x64 and/or ia64.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Make
Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
Use values from Manufacturer property from Win32_ComputerSystem.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeMake
Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
Use values from Manufacturer property from Win32_ComputerSystem.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Model
Specifies the supported Model(s)
Use values from Model property from Win32_ComputerSystem.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeModel
Specifies the excluded Model(s)
Use values from Model property from Win32_ComputerSystem.

```yaml
Type: String[]
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -URL
Specifies the URL for the Driver Package content.

```yaml
Type: String
Parameter Sets: PackageWithSettings, NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WQL
Specifies a list of WQL commands that can be used to match devices for this Driver Package.

```yaml
Type: String[]
Parameter Sets: NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PNPIDs
Specifies the list PNP IDs from the Driver Package.

```yaml
Type: Hashtable
Parameter Sets: NameWithSettings
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Definition
Specifies the Driver Package Definition

```yaml
Type: OrderedDictionary
Parameter Sets: NameWithDefinition
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipPNPDetection
Specifies, if the PnP IDs shouldn't be added to the Driver Package Definition file.

```yaml
Type: SwitchParameter
Parameter Sets: PackageWithSettings
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreSubSys
Specifies, if Subsystem part of the Hardware ID should be ignored when comparing Drivers
Will be added to the OSDrivers section of the definitino file.

```yaml
Type: SwitchParameter
Parameter Sets: PackageWithSettings
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Specifies if an existing Driver Package Definition file should be overwritten.

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
Specifies if the name and path to the new Driver Package Definition file should be returned.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

### System.String

## NOTES

## RELATED LINKS
