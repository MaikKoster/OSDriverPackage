---
external help file: OSDriver-help.xml
Module Name: OSDriver
online version:
schema: 2.0.0
---

# New-OSDriverCab

## SYNOPSIS
Creates a CAB file from a Directory or Child Directories

## SYNTAX

```
New-OSDriverCab [-Path] <String> [-LZXHighCompression] [-MakeCABsFromSubDirs] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a CAB file from a Directory or Child Directories

## EXAMPLES

### EXAMPLE 1
```
New-OSDriverCab -Path C:\Temp\Dell\LatitudeE10_A01
```

Creates MSZIP Fast Compression CAB from of C:\Temp\Dell\LatitudeE10_A01

### EXAMPLE 2
```
New-OSDriverCab -Path C:\Temp\Dell -LZXHighCompression -MakeCABsFromSubDirs
```

Creates LZX High Compression CABS from all subdirectories of C:\Temp\Dell

## PARAMETERS

### -Path
Directory to create the CAB from

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

### -LZXHighCompression
Forces LZX High Compression (Slower).
Unchecked is MSZIP Fast Compression

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

### -MakeCABsFromSubDirs
Creates CAB files from Path Subdirectories

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
NAME:	New-OSDriverCab.ps1
AUTHOR:	David Segura, david@segura.org
BLOG:	http://www.osdeploy.com
CREATED:	02/07/2018
VERSION:	1.0.7.1

## RELATED LINKS
