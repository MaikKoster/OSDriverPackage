---
external help file: OSDriver-help.xml
Module Name: OSDriver
online version:
schema: 2.0.0
---

# Get-OSDriverINFo

## SYNOPSIS
Finds specified driver files and returns all PNPIDs.

## SYNTAX

```
Get-OSDriverINFo [-Path] <String> [[-Files] <String[]>] [-ShowGrid] [<CommonParameters>]
```

## DESCRIPTION
Finds specified driver files and returns all PNPIDs.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
Specifies the path where to search for driver files

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
Specifies the name of the drivers files.
The name can include wildcards.
Default is '*.inf'

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

### -ShowGrid
Specifies if a gridview should be shown to select the driver files

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

## RELATED LINKS
