function Get-OSDriverInf {
    <#
    .SYNOPSIS
        Returns information about the specified driver.

    .DESCRIPTION
        Returns information about the specified driver and the related files by parsing the inf file.
        As it only parses the necesary information, this function is about 10 times faster than Get-WindowsDriver.

    #>
    [CmdletBinding()]
    [OutputType([array])]
    param (
        # Specifies the name and path for the driver file
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -match '\.inf') -and (-Not((Get-Item $_).PSIsContainer))})]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        $script:Logger.Trace("Get driver ('Path':'$Path')")

        $Driver = Get-Item $Path
        if ($Driver.Name -eq 'autorun.inf') {
            $script:Logger.Warn("Skipping '$Path'.")
        } elseif ($Driver.Extension -eq '.inf') {
            $script:Logger.Info("Get windows driver info from '$Path'")

            Import-SetupApiType

            $Result = [PSCustomObject]@{
                DriverFile = $Path
                CatalogFile = ''
                ClassName = ''
                ClassGuid = ''
                ProviderName = ''
                ManufacturerName = ''
                Version = ''
                Date = ''
                SourceFiles = New-Object 'System.Collections.Generic.List[string]'
                HardwareIDs = New-Object 'System.Collections.Generic.List[object]'
                #Platforms = New-Object 'System.Collections.Generic.List[string]'
                #OSVersions = New-Object 'System.Collections.Generic.List[string]'
            }

            $ErrorLine = 0
            $ReturnBuffer = [System.Text.StringBuilder]::new(4096)
            $hInf = [Win32.setupapi]::SetupOpenInfFile($Path, 0, 2, [ref] $ErrorLine)
            $InfContext = New-Object Win32.setupapi+INFCONTEXT
            [uint32]$RequiredSize = 0

            # Get class GUID
            if ([Win32.setupapi]::SetupFindFirstLine($hInf, 'Version', 'ClassGUID', [ref] $Infcontext)) {
                if ([Win32.setupapi]::SetupGetStringField([ref] $InfContext, 1, $ReturnBuffer, 4096, [ref]$requiredSize)) {
                    $Result.ClassGuid = $ReturnBuffer.ToString()
                    $script:Logger.Trace("ClassGuid: '$($Result.ClassGuid)'")
                    $TheGuid = [guid]::new($Result.ClassGuid)
                    # Get classname
                    if ([Win32.setupapi]::SetupDiClassNameFromGuid([ref]$theGuid, $ReturnBuffer, 4096, [ref]$requiredSize)) {
                        $Result.ClassName = $ReturnBuffer.ToString()
                    }
                }
            }

            # Get classname if not found based on GUID
            if ([string]::IsNullOrWhiteSpace($Result.ClassName) -and [Win32.setupapi]::SetupFindFirstLine($hInf, 'Version', 'Class', [ref] $InfContext)) {
                if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 1, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                    $Result.ClassName = $ReturnBuffer.ToString()
                }
            }

            # Fix classname if not found
            if ([string]::IsNullOrWhiteSpace($Result.ClassName)) {
                if ([string]::IsNullOrWhiteSpace($Result.ClassGUID)) {
                    $Result.ClassName = 'Unknown'
                } else {
                    $Result.ClassName = $Result.ClassGuid
                }
            }
            $script:Logger.Trace("ClassName: '$($Result.ClassName)'")

            # Get Date and Version
            if ([Win32.setupapi]::SetupFindFirstLine($hInf, 'Version', 'DriverVer', [ref] $InfContext)) {
                if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 1, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                    $Result.Date = $ReturnBuffer.ToString()
                }
                if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 2, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                    $Result.Version = $ReturnBuffer.ToString()
                }
            }

            # Set default values for Date and version if not found
            if ([string]::IsNullOrWhiteSpace($Result.Date)) {
                $Result.Date = "01/01/1990"
            }
            if ([string]::IsNullOrWhiteSpace($Result.Version)) {
                $Result.Version = "0.0"
            }
            $script:Logger.Trace("Date: '$($Result.Date)'")
            $script:Logger.Trace("Version: '$($Result.Version)'")

            # Get Catalogfile
            if ([Win32.setupapi]::SetupFindFirstLine($hInf, 'Version', 'CatalogFile', [ref] $Infcontext)) {
                if ([Win32.setupapi]::SetupGetStringField([ref] $InfContext, 1, $ReturnBuffer, 4096, [ref]$requiredSize)) {
                    $Result.CatalogFile = $ReturnBuffer.ToString()
                }
            }

            # Validate Catalogfile
            if ([string]::IsNullOrEmpty($Result.Catalogfile)) {
                $Result.Catalogfile = $Driver.Name -replace '.inf', '.cat'
            }

            # Add Driver and Catalogfile to list of source files
            $Result.SourceFiles.Add($Driver.Name)
            $Result.SourceFiles.Add($Result.CatalogFile)
            $script:Logger.Trace("CatalogFile: '$($Result.CatalogFile)'")

            $PnPContext = New-Object Win32.setupapi+INFCONTEXT
            if ([Win32.setupapi]::SetupFindFirstLine($hInf, 'Version', 'Provider', [ref]$InfContext)) {
                # Get Provider
                if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 1, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                    $Result.ProviderName = $ReturnBuffer.ToString()
                }
                $script:Logger.Trace("Provider: '$($Result.ProviderName)'")

                if ([Win32.setupapi]::SetupFindFirstLine($hInf, 'Manufacturer', [NullString]::Value, [ref]$InfContext)) {
                    $DeviceEntries = New-Object 'System.Collections.Generic.List[string]'
                    Do {
                        # Get Manufacturer
                        if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 0, $ReturnBuffer, 4096, [ref]$RequiredSize)){
                            $Result.ManufacturerName = $ReturnBuffer.ToString()
                            $script:Logger.Trace("Manufacturer: '$($Result.ManufacturerName)'")
                        }

                        # Get Architectures and OS Versions
                        if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, 1, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                            $Section = $ReturnBuffer.ToString()
                            $FieldCount = [Win32.setupapi]::SetupGetFieldCount([ref]$InfContext)
                            if ($FieldCount -eq 1) {
                                $Result.Plattforms.Add('x86')
                                $script:Logger.Trace("Adding platform 'x86'")
                            } else {

                                for ($Index = 2; $Index -le $FieldCount; $Index++) {
                                    if ([Win32.setupapi]::SetupGetStringField([ref]$InfContext, $Index, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                        $DeviceEntry = $ReturnBuffer.ToString()

                                        if (-Not($DeviceEntries.Contains($DeviceEntry))) {
                                            $DeviceEntries.Add($DeviceEntry)
                                        }

                                        if ($DeviceEntry.IndexOf('.', [StringComparison]::OrdinalIgnoreCase) -gt 0) {
                                            $DeviceMainEntry = $DeviceEntry.Substring(0, $DeviceEntry.IndexOf('.', [StringComparison]::OrdinalIgnoreCase))
                                            $DeviceSubEntry = $DeviceEntry.Substring(($DeviceEntry.IndexOf('.', [System.StringComparison]::OrdinalIgnoreCase) + 1))

                                            if (-Not($DeviceEntries.Contains($DeviceMainEntry))) {
                                                $DeviceEntries.Add($DeviceMainEntry)
                                            }

                                            # if (-Not($Result.OSVersions.Contains($DeviceSubEntry))) {
                                            #     $Result.OSVersions.Add($DeviceSubEntry)
                                            #     $script:Logger.Trace("Adding OS version '$DeviceSubEntry'")
                                            # }
                                        }

                                        # $Architecture = Resolve-Architecture -Architecture ($ReturnBuffer.ToString())

                                        # $flag = $false
                                        # foreach ($Platform in $Result.Platforms) {
                                        #     if ($Platform -eq $Architecture) {
                                        #         $Flag = $true
                                        #     }
                                        # }

                                        # if (-Not($Flag)) {
                                        #     $Result.Platforms.Add($Architecture)
                                        #     $script:Logger.Trace("Adding platform '$Architecture'")
                                        # }
                                    }
                                }
                            }
                        }

                        # Get Hardware IDs
                        if ([Win32.setupapi]::SetupFindFirstLine($hInf, $Section, [NullString]::Value, [ref]$PnPContext)) {
                            # # 'Device' without any further information means x86
                            # $Flag = $false
                            # foreach ($Platform In $Result.Platforms) {
                            #     if ($Platform -eq 'x86') {
                            #         $flag = $true
                            #     }
                            # }

                            # if (-Not($Flag)) {
                            #     $Result.Platforms.Add('x86')
                            #     $script:Logger.Trace("Adding platform x86'")
                            # }

                            do {
                                $FieldCount = [Win32.setupapi]::SetupGetFieldCount([ref]$PnPContext)
                                for ($Index = 2; $Index -le $FieldCount; $Index++) {
                                    if ([Win32.setupapi]::SetupGetStringField([ref]$PnPContext, $Index, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                        # Get PNP ID
                                        $HardwareID = [PSCustomObject]@{
                                            HardwareID = ($ReturnBuffer.ToString())
                                            HardwareDescription = ''''
                                            Architecture = 'x86'
                                        }

                                        # Get Description
                                        if ([Win32.setupapi]::SetupGetStringField([ref]$PnPContext, 0, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                            $HardwareID.HardwareDescription = ($ReturnBuffer.ToString())
                                        }

                                        if (-Not($Result.HardwareIDs.Contains($HardwareID))) {
                                            $Result.HardwareIDs.Add($HardwareID)
                                            $script:Logger.Trace("Adding supported hardware: HardwareID '$($HardwareID.HardwareID)', '$($HardwareID.HardwareDescription)', '$($HardwareID.Architecture)'.")
                                        }
                                    }
                                }
                            } while ([Win32.setupapi]::SetupFindNextLine([ref] $PnPContext, [ref] $PnPContext))
                        }

                        foreach ($DeviceEntry in $DeviceEntries) {
                            $Architecture = Resolve-Architecture -Architecture $DeviceEntry
                            if ([Win32.setupapi]::SetupFindFirstLine($hInf, "$Section.$DeviceEntry", [NullString]::Value, [ref]$PnPContext)) {
                                # $OSVersion = $DeviceEntry.Substring(($DeviceEntry.IndexOf('.', [System.StringComparison]::OrdinalIgnoreCase) + 1))
                                do {
                                    $FieldCount = [Win32.setupapi]::SetupGetFieldCount([ref]$PnPContext)
                                    for ($Index = 2; $Index -le $FieldCount; $Index++) {
                                        if ([Win32.setupapi]::SetupGetStringField([ref]$PnPContext, $Index, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                            # Index 0 = Description of device
                                            # Index 2+ = PnPID
                                            # Get PNP ID
                                            # TODO: What is the current architecture?
                                            $HardwareID = [PSCustomObject]@{
                                                HardwareID = ($ReturnBuffer.ToString())
                                                HardwareDescription = ''
                                                Architecture = $Architecture
                                            }

                                            # Get Description
                                            if ([Win32.setupapi]::SetupGetStringField([ref]$PnPContext, 0, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                                $HardwareID.HardwareDescription = ($ReturnBuffer.ToString())
                                            }

                                            if (-Not($Result.HardwareIDs.Contains($HardwareID))) {
                                                $Result.HardwareIDs.Add($HardwareID)
                                                $script:Logger.Trace("Adding supported hardware: HardwareID '$($HardwareID.HardwareID)', '$($HardwareID.HardwareDescription)', '$($HardwareID.Architecture)'.")
                                            }
                                        }
                                    }
                                } while ([Win32.setupapi]::SetupFindNextLine([ref] $PnPContext, [ref] $PnPContext))
                            }
                        }
                    } while ([Win32.setupapi]::SetupFindNextLine([ref] $InfContext, [ref] $InfContext))
                }
            }

            # Get Source disks and files
            $Index = 0
            $SourceDisksFiles = @{}
            $SourceDisksNames = @{}

            for ($Index = 0; [Win32.setupapi]::SetupEnumInfSections($hInf, $Index, $ReturnBuffer, 4096, [ref] $RequiredSize); $Index++) {
                $Section = $ReturnBuffer.ToString()
                if ($Section -like 'SourceDisksFiles*') {
                    if ([Win32.setupapi]::SetupFindFirstLine($hInf, $Section, [NullString]::Value, [ref] $PNPContext)) {
                        do {
                            $FieldCount = [Win32.setupapi]::SetupGetFieldCount([ref]$PnPContext)
                            if ([Win32.setupapi]::SetupGetStringField([ref]$PnPContext, 0, $ReturnBuffer, 4096, [ref]$RequiredSize)) {
                                $Filename = $ReturnBuffer.ToString()
                            } else {
                                $Filename = ''
                            }

                            # Get Disk
                            if ([Win32.setupapi]::SetupGetStringField([ref] $PNPContext, 1, $ReturnBuffer, 4096, [ref] $RequiredSize)) {
                                $Diskname = $ReturnBuffer.ToString()
                            } else {
                                $Diskname = ''
                            }

                            # Add suffix to Disk to be able to separate different architectures/osversions if necessary
                            if (-Not([string]::IsNullOrWhiteSpace($Diskname))) {
                                if ($Section -like '*.*') {
                                    $Suffix = $Section.Substring($Section.IndexOf('.'))
                                    $Diskname = "$Diskname$Suffix"
                                }
                            }

                            # Add optional subfolder to the filename
                            if ($FieldCount -gt 1) {
                                if ([Win32.setupapi]::SetupGetStringField([ref] $PNPContext, 2, $ReturnBuffer, 4096, [ref] $RequiredSize)) {
                                    if (-Not([string]::IsNullOrWhitespace($ReturnBuffer.ToString()))) {
                                        $Filename = "$($ReturnBuffer.ToString())\$Filename"
                                    }
                                }
                            }

                            # Add to list of SourceDisksFiles
                            if (-Not([string]::IsNullOrWhiteSpace($Filename))) {
                                $SourceDisksFiles[$Filename] = $Diskname
                            }
                        } while ([Win32.setupapi]::SetupFindNextLine([ref] $PNPContext, [ref] $PNPContext))
                    }
                } elseif ($Section -like 'SourceDisksNames*') {
                    if ([Win32.setupapi]::SetupFindFirstLine($hInf, $Section, [NullString]::Value, [ref]$PnPContext)) {
                        do {
                            if ([Win32.setupapi]::SetupGetStringField([ref] $PNPContext, 0, $ReturnBuffer, 4096, [ref] $RequiredSize)) {
                                $Diskname = $ReturnBuffer.ToString()
                            }

                            # optional subfolder is stored in 4th position
                            if (([Win32.setupapi]::SetupGetFieldCount([ref]$PnPContext)) -ge 4) {
                                if ([Win32.setupapi]::SetupGetStringField([ref] $PNPContext, 4, $ReturnBuffer, 4096, [ref] $RequiredSize)) {
                                    $DiskPath = $ReturnBuffer.ToString()

                                } else {
                                    $DiskPath = ''
                                }
                            } else {
                                $DiskPath = ''
                            }

                            # Add suffix to Diskname to be able to separate different architectures/osversions if necessary
                            if ($Section -like '*.*') {
                                $Suffix = $Section.Substring($Section.IndexOf('.'))
                                $Diskname = "$Diskname$Suffix"
                            }

                            # Add to list of SourceDisksNames
                            $SourceDisksNames[$Diskname] = $DiskPath
                        } while ([Win32.setupapi]::SetupFindNextLine([ref] $PNPContext, [ref] $PNPContext))
                    }
                }
            }

            # Assemble path to SourceDisksFile with Disk
            $TempSourceFiles = @{}
            foreach ($SourceDisksFile in $SourceDisksFiles.Keys) {
                $Diskname = $SourceDisksFiles[$SourceDisksFile]

                if (-Not([string]::IsNullOrWhiteSpace($Diskname))) {
                    # Check if there is a SourceDisk with this name
                    if ($SourceDisksNames.ContainsKey($Diskname)) {
                        $TempFilename = "$($SourceDisksNames[$Diskname])\$SourceDisksFile"
                        $TempSourceFiles[$TempFilename] = ''
                    } else {
                        # Try without any suffix first (if suffix is used)
                        if ($Diskname -like '*.*') {
                            $TempDiskname = $Diskname.Substring(0, $Diskname.IndexOf('.'))

                            if ($SourceDisksNames.ContainsKey($TempDiskname)) {
                                $TempFilename = "$($SourceDisksNames[$TempDiskname])\$SourceDisksFile"
                                $TempSourceFiles[$TempFilename] = ''
                            } else {
                                # Iterate through all Disks, as there might be a suffix on the disk but not on the file
                                foreach ($SourceDisk In $SourceDisksNames.Keys) {
                                    if ($SourceDisk -like "$TempDiskName.*") {
                                        # Add to list of Source
                                        $TempFilename = "$($SourceDisksNames[$SourceDisk])\$SourceDisksFile"
                                        $TempSourceFiles[$TempFilename] = ''
                                    }
                                }
                            }
                        } else {
                            # Iterate through all Disks, as there might be a suffix on the disk but not on the file
                            foreach ($SourceDisk In $SourceDisksNames.Keys) {
                                if ($SourceDisk -like "$DiskName.*") {
                                    # Add to list of Source
                                    $TempFilename = "$($SourceDisksNames[$SourceDisk])\$SourceDisksFile"
                                    $TempSourceFiles[$TempFilename] = ''
                                }
                            }
                        }
                    }
                } else {
                    # No Diskname confgured, add filename only as it's in the same root as the inf file
                    $TempSourceFiles[$SourceDisksFile] = ''
                }
            }

            # Clean up path and test availability of file
            $DriverRoot = $Driver.Directory.FullName
            foreach ($TempSourceFile in $TempSourceFiles.Keys) {
                $Valid = $true
                $TempFilename = Format-Filepath -Filepath $TempSourceFile
                $SourceDiskFilePath = Join-Path -Path $DriverRoot -ChildPath $TempFilename
                if (-Not(Test-Path -Path $SourceDiskFilePath)) {
                    $SourceDiskFileCompressed = "$($TempSourceFile.Substring(0, ($TempSourceFile.Length - 1)))_"
                    $SourceDiskFileCompressedPath = Join-Path -Path $DriverRoot -ChildPath $SourceDiskFileCompressed
                    if (Test-Path -Path $SourceDiskFileCompressedPath) {
                        # "Real" file doesn't exist, but compressed one does
                        $script:Logger.Debug("SourceDiskFile '$SourceDiskFile' is still compressed. Replacing with '$SourceDiskFileCompressed'.")
                        $TempFilename = $SourceDiskFileCompressed
                    } else {
                        $script:Logger.Warn("SourceDiskFile '$SourceDiskFile' does not exist. Removing file from result.")
                        $Valid = $false
                    }
                }

                if ($Valid) {
                    if (-Not($Result.SourceFiles.Contains($TempFilename))) {
                        $Result.SourceFiles.Add($TempFilename)
                    }
                }
            }

            [Win32.setupapi]::SetupCloseInfFile($hInf)
            $Result
        }
    }

    begin {

        Function Import-SetupApiType {
            [CmdLetBinding()]
            param()
            process{
                $script:Logger.Trace("Importing setupapi.dll ...")

                # Define inf file handlers from setupapi.dll
                $MethodDefinition = @'
[DllImport("setupapi.dll", EntryPoint = "SetupOpenInfFileW", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern IntPtr SetupOpenInfFile(string infFile, uint infClass, uint infStyle, out uint errorLine);

[DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern void SetupCloseInfFile(IntPtr hInf);

[DllImport("setupapi.dll", EntryPoint = "SetupFindFirstLineW", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SetupFindFirstLine(IntPtr hInf, string section, string key, out INFCONTEXT context);

[DllImport("setupapi.dll", EntryPoint = "SetupEnumInfSectionsW", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SetupEnumInfSections(IntPtr hInf, uint index, System.Text.StringBuilder returnBuffer, uint returnBufferSize, out uint requiredSize);

[DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SetupFindNextLine(ref INFCONTEXT inContext, out INFCONTEXT outContext);

[DllImport("setupapi.dll", EntryPoint = "SetupGetStringFieldW", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SetupGetStringField(ref INFCONTEXT context, uint index, System.Text.StringBuilder returnBuffer, uint returnBufferSize, out uint requiredSize);

[DllImport("setupapi.dll", EntryPoint = "SetupDiClassNameFromGuidW", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool SetupDiClassNameFromGuid(ref Guid theGuid, System.Text.StringBuilder returnBuffer, uint returnBufferSize, out uint requiredSize);

[DllImport("setupapi.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint SetupGetFieldCount(ref INFCONTEXT context);

[DllImport("setupapi.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern bool SetupVerifyInfFile(string infName, IntPtr AltPlatformInfo, ref INF_SIGNER_INFO InfSignerInfo);

[DllImport("wintrust.dll")]
public static extern uint WinVerifyTrust(IntPtr hwnd, [In] ref Guid pguidAction, IntPtr pvData);

public struct INFCONTEXT
{
  public IntPtr Inf;
  public IntPtr CurrentInf;
  public uint Section;
  public uint Line;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
public struct INF_SIGNER_INFO
{
  public uint cbSize;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
  public string CatalogFile;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
  public string DigitalSigner;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
  public string DigitalSignerVersion;
}

public struct WINTRUST_DATA
{
  public uint cbStruct;
  public IntPtr pPolicyCallbackData;
  public IntPtr pSIPClientData;
  public uint dwUIChoice;
  public uint fdwRevocationChecks;
  public uint dwUnionChoice;
  public IntPtr pUnionData;
  public uint dwStateAction;
  public IntPtr hWVTStateData;
  public IntPtr pwszURLReference;
  public uint dwProvFlags;
  public uint dwUIContext;
}
'@
                try {
                    $Setupapi = [Win32.setupapi]
                } catch {
                    $Setupapi = Add-Type -MemberDefinition $MethodDefinition -Name 'setupapi' -Namespace 'Win32' -PassThru
                }
            }
        }

        Function Resolve-Architecture {
            [CmdLetBinding()]
            [OutputType([System.String])]
            param(
                [string]$Architecture
            )

            process {

                if ($Architecture -like '*NTx86*') {
                    'x86'
                } elseif ($Architecture -like '*NTamd64*') {
                    'x64'
                } elseif ($Architecture -like '*NTia64*') {
                    'ia64'
                } elseif ($Architecture -like '*NT*') {
                    'x86'
                }
            }
        }

         Function Format-Filepath {
            [CmdLetBinding()]
            param(
                [Parameter(Mandatory, Position=0)]
                [string]$Filepath
            )

            process {
                # Fix '\\' in path name
                $Result = $Filepath.Trim() -replace '\\\\', '\'
                # Remove any '"'
                $Result = $Result.Trim() -replace '"', ''
                # Remove facing and trailing '\'
                $Result = $Result.Trim('\')
                # Remove facing '.\'
                $Result = $Result.TrimStart('.\')

                $Result
            }
        }
    }
}
