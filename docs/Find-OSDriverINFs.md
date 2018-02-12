---
external help file: OSDriver-help.xml
Module Name: OSDriver
online version:
schema: 2.0.0
---

# Find-OSDriverINFs

## SYNOPSIS
Finds specified files, estimates size, option to remove Parent directory

## SYNTAX

```
Find-OSDriverINFs [-Path] <String> [[-Files] <String>] [-RemoveDirectories] [<CommonParameters>]
```

## DESCRIPTION
Finds specified files, estimates size, option to remove Parent directory

## EXAMPLES

### EXAMPLE 1
```
Find-OSDriverINFs -Path C:\OSDrivers\Intel
```

Finds all INF files in C:\OSDrivers\Intel

### EXAMPLE 2
```
Find-OSDriverINFs -Path C:\OSDrivers\Intel -RemoveDirectories
```

Finds all INF files in C:\OSDrivers\Intel.
Removes Parent directory of selected files

## PARAMETERS

### -Path
Directory to search for INF files

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

### -Files
Files to Include.
Default is *.inf

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: *.inf
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoveDirectories
Removes the directory containing the file

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
NAME:	Find-OSDriverINFs.ps1 
AUTHOR:	David Segura, david@segura.org 
BLOG:	http://www.osdeploy.com 
CREATED:	02/07/2018 
VERSION:	1.0.7.1

## RELATED LINKS
