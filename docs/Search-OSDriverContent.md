---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Search-OSDriverContent

## SYNOPSIS
Searches in INF files for a text string

## SYNTAX

```
Search-OSDriverContent [-Path] <String> [[-Files] <String[]>] [[-FindText] <String>] [<CommonParameters>]
```

## DESCRIPTION
Searches in INF files for a text string

## EXAMPLES

### EXAMPLE 1
```
Search-OSDriverContent -Path C:\DeploymentShare\OSDrivers -FindText "VEN_8086&DEV_1902"
```

Searches in all INF files for "VEN_8086&DEV_1902".
Results in Gridview

### EXAMPLE 2
```
Search-OSDriverContent -Path C:\DeploymentShare\OSDrivers -Files *.txt -FindText "VEN_8086&DEV_1902"
```

Searches in all TXT files for "VEN_8086&DEV_1902".
Results in Gridview

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
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: *.inf
Accept pipeline input: False
Accept wildcard characters: False
```

### -FindText
Text string to search

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
NAME:	Search-OSDriverContent.ps1
AUTHOR:	David Segura, david@segura.org
BLOG:	http://www.osdeploy.com
CREATED:	02/07/2018
VERSION:	1.0.7.1

## RELATED LINKS
