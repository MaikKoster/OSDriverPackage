---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Apply-OSDriverPackage

## SYNOPSIS
Applies the specified Driver Package(s) to the current computer.

## SYNTAX

```
Apply-OSDriverPackage [-Path] <String> [-Destination] <String> [-Name <String[]>] [-Tag <String[]>]
 [-OSVersion <String[]>] [-NoMake] [-NoModel] [-NoHardwareID] [-NoWQL] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Apply-OSDriverPackage CmdLet expands the content of the specified Driver Package(s) to the current computer.

## EXAMPLES

### EXAMPLE 1
```
Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers'
```

Applies all matching Driver Packages to the local computer.
Matching methods used are Make, Model,
HardwareID, and WQL commands as defined within the Driver Package.

### EXAMPLE 2
```
Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers' -Tag 'Core' -NoMake -NoModel
```

Applies all matching Driver Packages to the local computer.
Matching methods used are the tag 'Core',
HardwareID, and WQL commands as defined within the Driver Package.
Make and Model information isn't used.

### EXAMPLE 3
```
Apply-OSDriverPackage -Path $DriverPackageSource -DestinationPath 'C:\Drivers' -NoHardwareID -NoWQL
```

Applies all matching Driver Packages to the local computer.
Matching methods used are Make and Model.
HardwareID and WQL commands aren't used.

## PARAMETERS

### -Path
Specifies the path to the Driver Package.
If a folder is specified, all Driver Packages within that folder and subfolders
will be applied, based on the additional conditions

```yaml
Type: String
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Destination
Specifies the path to which the specified Driver Package(s) should be extracted to.

```yaml
Type: String
Parameter Sets: (All)
Aliases: TargetPath

Required: True
Position: 2
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

### -NoMake
Specifies, if the Make (Manufacturer) information of the current computer should not be
used to select the appropiate driver package.
On default, the Manufacturer property of
the Win32_ComputerSystem class of the current computer will be used to filter the
appropriate driver packages.

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

### -NoModel
Specifies, if the Model information of the current computer should not be used to select
the appropiate driver package.
On default, the Model property of the Win32_ComputerSystem
class of the current computer will be used to filter the appropriate driver packages.

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

### -NoHardwareID
Specifies if the Hardware IDs of the current computer should not be used to select the
appropriate Driver Packages.
On default, All Hardware IDs of the current computer will be
compared against the list of Hardware IDs stored in the driver package definition file.
If they match, the driver package will be applied.

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

### -NoWQL
Specifies if the the WQL statements in the driver package definition files should not be
used to select the appropriate driver packages.
On default, any existing WQL query will be
executed, and if it returns a result, the driver package will be applied.

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
Currently this CmdLet only expands the content of the Driver Package to the specified path.
It's primary
purpose is to be used as part of the MDT/ConfigMgr OSD deployment.

## RELATED LINKS
