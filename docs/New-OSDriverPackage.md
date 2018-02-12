---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# New-OSDriverPackage

## SYNOPSIS
Creates a new Driver Package.

## SYNTAX

```
New-OSDriverPackage [-DriverPackageSourcePath] <String> [[-OSVersion] <String[]>]
 [[-ExcludeOSVersion] <String[]>] [[-Make] <String[]>] [[-ExcludeMake] <String[]>] [[-Model] <String[]>]
 [[-ExcludeModel] <String[]>] [[-URL] <String>] [-ShowGrid] [-SkipPNPDetection] [-Force] [-KeepFiles]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-OSDriverPackage CmdLet creates a new Driver Package from an existing path, containing
the drivers.
A Driver Package consist of a compressed archive of all drivers, plus a Definition
file with further information about the drivers inside the Driver Package.
Per convention, the
Definition file and the Driver Package have the same name.
Additional information about the applicable hardware like Make and Model can be supplied using
the corresponding parameters.
These will be added to the Definition file.
The list of PnPIDs and corresponding WQL queries will the generated on default, but can be
optionally be skipped.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DriverPackageSourcePath
Specifies the name and path of the Driver Package content
The Definition File will be named exactly the same as the Driver Package.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: True
Position: 1
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
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Make
Specifies the supported Make(s)/Vendor(s)/Manufacture(s).
Use values from Manufacturer property from Win32_ComputerSystem.

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

### -ExcludeMake
Specifies the excluded Make(s)/Vendor(s)/Manufacture(s).
Use values from Manufacturer property from Win32_ComputerSystem.

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
Specifies the supported Model(s)
Use values from Model property from Win32_ComputerSystem.

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

### -ExcludeModel
Specifies the excluded Model(s)
Use values from Model property from Win32_ComputerSystem.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -URL
Specifies the URL for the Driver Package content.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowGrid
Specifies if a grid should be shown to select the inf files and drivers.

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

### -SkipPNPDetection
Specifies, if the PnP IDs shouldn't be extracted from the Driver Package
Using this switch will prevent the generation of the WQL and PNPIDS sections of
the Definition file.

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

### -Force
Specifies if an existing Driver Package should be overwritten.

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

### -KeepFiles
Specifies, if the source files should be kept, after the Driver Package has been created.
On default, all source content will be removed.

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
Specifies if the name and path of the Driver Package and Definition files should be returned.

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

## NOTES

## RELATED LINKS
