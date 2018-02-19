# Creating and maintaining Driver Packages

## Introduction
This shall give a quick run down on some typical tasks handled by this PowerShell Module. It's centered around the idea of separating common, general **Drivers** into **Core Driver Packages**, that apply to the majority of machines within a certain environment. And having these **Core Drivers** then removed from **Driver Packages** that are created for individual or multiple models. This allows to shrink the total size of **Driver Packages** that need to be handled and also allows for easier updating of critical drivers.
This guide does not cover the actuall deployment and installation of Driver Packages. It's solely about handling the Driver Packages for now. More content to be added soon.

## Definitions

### Driver
A **Driver** is defined as the inf file, that contains all the necessary information about applicable Hardware IDs, referenced files, etc.

### Driver Package
A **Driver Package** is defined as a collection of individual Drivers, that are bundled together for e.g. a specific computer model. It consists of a compressed cab file that contains all the files, a json file with the same name containing further information about each individual Driver within the Driver Package and a txt file with the same name that contains further information about what machines are applicable to this Driver Package.

## Step by Step
The following will go through some typical steps to demonstrate the usage of this module.

### Folder Structure
The module doesn't rely on a specific folder structure, rather identifying applicable **Driver Packages** by Meta tags assigned to reach package. However, it's recommended to create a proper folder structure to properly organize the individual Driver Packages. For this sample, please create a folder structure as following:

* DriverRepository
  * Core
    * Bluetooth
    * Chipset
    * Dock
    * Network
    * Storage
    * Wireless
    * Video
  * Family Packages
  * Model Packages

All following steps assume, that the PowerShell commands are called from the root of the Driver Repository. So if you created it in the root of C:\, please change your current location to
```
cd C:\DriverRepository
```

### Create a Driver Package
As everything in this PowerShell module is built around **Driver Packages**, you must create some.

To be able to create a Driver Package, we first need to have a couple drivers. For this sample, we download the [Intel Graphics Driver for Windows](https://downloadcenter.intel.com/download/27484/Graphics-Intel-Graphics-Driver-for-Windows-15-65-?product=96553). Make sure you select the zip version for download.

Extract the content into **'DriverRepository\Core\Video\Intel\Video Intel 15.65.3.4944 Win10 x64'**. It's helpful to use descriptive names and include information like OS or the version number. It would also be possible to create subfolder per version or whatever structure feels more appropriate.

To allow to easily search for specific Driver Packages, it supports the use of a variety of tag based identifiers. In this sample, we specify the **OSVersion** to be Windows 10 x64 and give it two generic tags of **Core** and **Video**. We supply the **-Verbose** parameter, to show in detail, what is happening, as the process can take some time and is completely silent, like the majority of commands in this module. You probably wouldn't use this switch on a regular basis. We also supply the **-PassThru** parameter, as that will return more information about the Driver Package, that you created and pipe it to the **Format-List** CmdLet to have some easier to read output. Execute the following PowerShell command to scan the drivers in that folder and create a Driver Package:
```
New-OSDriverPackage -Path '.\Core\Video\Intel\Video Intel 15.65.3.4944 Win10 x64' -OSVersion 'Win10-x64' -Tag 'Core', 'Video' -PassThru -Verbose | Format-List
```
Inspect the information about the Driver Package that was returned by the CmdLet. It  contains the path to the compressed content (cab file), the path to the Definition file, the **Definition** which contains the tags and some further information that is used for proper filtering later and finally a list of Drivers with some additional information about each.

To have something we can work with, we now need at least a second Driver Package. Preferably one that supports a specific Model. Lets take the [Dell Latitude 5285 Windows 10 Driver Pack](http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12269.latitude-5285-windows-10-driver-pack), but any other will do as well. Assuming the content of the driver pack has been extracted to **'DriverRepository\Model Packages\Dell Latitude 5285 Win10 x64'**, the command to create the Driver Package could now look like the following. As the driver pack contains a lot more drivers, the **-PassThru** and **-Verbose** parameters are supplied again to actually see what is happening. However not that **Make** and **Model** tags are specified this time. Any structure that make sense can be applied here:
```
New-OSDriverPackage -Path '.\Model Packages\Dell Latitude 5285 Win10 x64' -OSVersion 'Win10-x64' -Make 'Dell' -Model 'Latitude 5285' -PassThru -Verbose | Format-List
```

### Compare Driver Packages
Get an instance of each Driver Package that you just created.
```
$CoreVideo = Get-OSDriverPackage -Path '.\Core\Video\Intel\Video Intel 15.65.3.4944 Win10 x64.cab'

$Dell5285 = Get-OSDriverPackage -Path '.\Model Packages\Dell Latitude 5285 Win10 x64.cab'
```
To compare two Driver Packages, the Compare-OSDriverPackage CmdLet can be used. It takes one or multiple **Core Driver Packages* and compare it against one **Driver Package*. Logic wise, it will go through all the drivers in all the **Core Driver Packages** and check, if the **Driver Package** contains drivers with the same name (of the inf file). For all those that match, it compares the version. If the version in the **Core Driver Package** is the same or higher, it will then compare every **Hardware ID (PnPID)**. If the supported Hardware IDs in the driver from the **Core Driver Package** cover every Hardware ID from the corresponding driver in the **Driver Package**, that particular driver could be replaced. So execute
```
Compare-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285
```

The output from the last step shows only 2 matching drivers. Both Audio drivers named  'IntcDAud.inf' but with two different versions. For both, the **Replace** property is set to False, which means that they can't be replaced by the **Core Driver Package**. The property **MissingHardwareIDs** contains a list of Hardware IDs, that are missing from the **Core Driver Package**. It's quite common, that individual HardwareIDs might be missing. They could refer to outdated components, that are no longer supported by the vendor, in which case they are safe to be ignored and replace the whole Driver. However it's sometimes hard to identify these individual Hardware IDs, especially if they don't come with a meaningful description. One possible way to approach this, is to get the list of devices from a computer and then to make sure that all those **critical** devices are covered. Call the following function to get a list of devices from the current computer.
```
Get-PnPDevice
```
This returns a pretty long list of all Plug-And-Play devices registered on the computer. The necessary information is stored in the **HardwareID** property. To make it easier, the **Get-PnPDevice** CmdLet supports to have the output limited to the HardwareIDs by supplying the **HardwareIDOnly** switch, which then allows to easily store the list of Hardware IDs in a variable,
```
$CriticalIDs = Get-PnPDevice -HardwareIDOnly
```
or write it to a textfile to be used later
```
Get-PnPDevice -HardwareIDOnly -ComputerName 'Testcomputer' | Set-Content '.\CriticalIDs.txt'
```
For example running this on the test Dell Latitude 5285 showed, that none of the missing Hardware IDs is really relevant. So take the list of critical Hardware IDs and execute it again supplying them.
```
Compare-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285 -CriticalIDs $CriticalIDs
```
As you probably don't have access this exact model, the related HardwareIDs are written down for demonstration purposes.
```
$CriticalIDs = @('INTELAUDIO\FUNC_01&VEN_8086&DEV_280B&SUBSYS_80860101', 'INTELAUDIO\FUNC_01&VEN_10EC&DEV_0225&SUBSYS_102807A4')

Compare-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285 -CriticalIDs $CriticalIDs
```
This time, both drivers show up as **replace**-able.

But we are not done yet. The Driver Package, that we downloaded from Intel should actually cover the video driver as well. So why doesn't it show up in this list? This is a particular annoying issue. Some vendors like Dell tend to tweak **and rename** the driver file. In this particular case, Dell renamed the original driver file from intel from **igdlh64.inf** into **ki121783.inf**. Why does Dell do this? Good question, ask Dell ;)
This can be tough to find and luckily most vendors to this. However especially on such large drivers like for video, it's relatively easy to spot, as there are typically not that many inf files at all. So all what we need to do now, is to tell the CmdLet, to also consider a different name for this particular driver file. You can do this using the **Mappings** parameter supplying a hashtable with the mapping of those files.

```
$Mappings = @{
    'igdlh64.inf' = 'ki121783.inf'
}
Compare-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285 -CriticalIDs $CriticalIDs -Mappings $Mappings
```
When executing this command, it finally shows a third driver that can be replaced.

### Remove Drivers from Driver Package
You used the **CompareOSDriverPackage** CmdLet to get a list of drivers, that you could now filter for the ones to be replaced by the **Core Driver Package(s)**. While there are CmdLets available to expand the cab (**Expand-OSDriverPackage**), remove the driver from a **Driver Package** (**Remove-OSDriver**), update the list of drivers (**Read-OSDriverPackage**), and finally create a cab file again (**Compress-OSDriverPackage**), there is a CmdLet that does all this for you in one go. Just call the **Clean-OSDriverPackage** to remove those drivers from the **Driver Package**:
```
Clean-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285 -CriticalIDs $CriticalIDs -Mappings $Mappings -Verbose

```
Using the **Verbose** parameter allows you to see exactly what is happening and how it's going through all the above described steps. At the end of the process, it shows an overview about the difference:

```
DriverPackage  : C:\demo\OSDriverPackages\Model Packages\Dell Latitude 5285 Win10 x64.cab
OldCabSize     : 560947094
NewCabSize     : 274391623
OldFolderSize  : @{Dirs=219; Files=1128; Bytes=1350956352}
NewFolderSize  : @{Dirs=184; Files=830; Bytes=598938999}
OldDriverCount : 116
NewDriverCount : 113
```
So we were able to remove 3 drivers, related to 34 folders, 298 files and ~717MB in uncompressed size. Even compressed the Driver Package is now 273MB or 51% smaller. And you have to keep in mind, that this was from a single **Core Driver Package** only, that typically covers a broad variety of other models as well. Now adding appropriate **Core Driver Packages** for **Bluetooth**, **Chipset**, **Network**, **Storage**, **Wireless**, etc.
For sure there is a certain administrative effort related to this approach. So it's important to properly weight the benefits of drastically smaller Driver Packages to the increased amount of administrative effort and complexity.
The main purpose of this PowerShell module is to reduce this administrative effort and the complexity, so that this method is usable by a larger audience.
