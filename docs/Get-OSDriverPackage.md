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
Get-OSDriverPackage [-Path] <String> [-Name <String[]>] [-Tag <String[]>] [-OSVersion <String[]>]
 [-Architecture <String[]>] [-Make <String[]>] [-Model <String[]>] [-HardwareIDs <String[]>] [-UseWQL]
 [-ReadDrivers] [-CreateTSVariables] [<CommonParameters>]
```

## DESCRIPTION
The Get-OSDriverPackage CmdLet gets one or multiple Driver Packages based on the supplied conditions.
If no value for a specific criteria has been supplied, it will be ignored.
Multiple criteria will be treated as AND.
Multiple values for the same criteria will be treated as OR.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
Specifies the path to the Driver Package.
If a folder is specified, all Driver Packages within that folder and subfolders will be returned

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

### -HardwareIDs
Specifies a list of HardwareIDs, that should be used to identify related Driver Package(s).

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

### -UseWQL
Specifies if the WQL command specified in the driver package definition file should be
executed to identify matching Driver Package(s).

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

### -ReadDrivers
Specifies, if the List of drivers should be read.
On default, the "Drivers" property will be $null.
If enabled, all Drivers will be read into the
Drivers property, which can take a considerable amount of time.
Especially, if the drivers haven't
been processed before.

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

### -CreateTSVariables
Specifies, if a Task Sequence variable should be created for every Driver Package that was found
based on the supplied conditions.
The Task Sequence variable will have the ID of the Driver Package
as name and a value of 'Install'.
This allows to easily create filters inside of a Task Sequence
based on the Unique ID of a Driver Package and install it dynamically, without duplicating the
filter criterias.
It will only work if executed within a Task Sequence.

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

## NOTES
A Driver Package is defined by the Driver Package Definition file ({DriverPackageName}.txt).
To allow for
a performant selection process, only txt files with an 'OSDrivers' section will be treated as valid Driver Packages

## RELATED LINKS
