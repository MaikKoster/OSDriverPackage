---
external help file: OSDriver-help.xml
Module Name: OSDriver
online version:
schema: 2.0.0
---

# Expand-OSDriver

## SYNOPSIS
Optionally expands compressed drivers.
Optionally removes Nvidia Driver junk

## SYNTAX

```
Expand-OSDriver [-Path] <String> [-ExpandCompressedFiles] [-RemoveNvidiaJunk] [<CommonParameters>]
```

## DESCRIPTION
Optionally expands compressed drivers.
Optionally removes Nvidia Driver junk

## EXAMPLES

### EXAMPLE 1
```
Edit-ExpandOSDriver -Path C:\OSDrivers\Nvidia -ExpandCompressedFiles -RemoveNvidiaJunk
```

## PARAMETERS

### -Path
Directory containing Drivers

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

### -ExpandCompressedFiles
Expands compressed files *.bi,*.cf,*.cp,*.dl,*.ex,*.hl,*.pd,*.sy,*.tv,*.xm

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

### -RemoveNvidiaJunk
Removes directories named Display.NView, Display.Optimus, Display.Update, DisplayDriverCrashAnalyzer, GFExperience, GFExperience.NvStreamSrv, MSVCRT, nodejs, NV3DVision, NvBackend, NvCamera, NvContainer, NVI2, NvTelemetry, NVWMI, PhysX, ShadowPlay, Update.Core

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
NAME:	Edit-ExpandOSDriver.ps1
AUTHOR:	David Segura, david@segura.org
BLOG:	http://www.osdeploy.com
CREATED:	02/07/2018
VERSION:	1.0.7.1

## RELATED LINKS
