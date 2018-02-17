---
external help file: OSDriverPackage-help.xml
Module Name: OSDriverPackage
online version:
schema: 2.0.0
---

# Read-OSDriverPackage

## SYNOPSIS
Scans for all drivers in a Driver package and creates info file.

## SYNTAX

```
Read-OSDriverPackage [-Path] <String> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
The Read-OSDriverPackage CmdLet scans all drivers in the specified Driver Package and creates
an info file cointaining useful information for further evaluation/comparison, as getting the
Driver Details is a very time consuming process.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Path
Specifies the path to the Driver Package.
If a cab file is specified, the content will be temporarily extracted.

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

### -PassThru
Specifies if the Driver Package should be returned

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
