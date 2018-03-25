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

### Install the Module

First things first. If you haven't done yet, install and import the module.

### Folder Structure

The module doesn't rely on a specific folder structure, rather identifying applicable **Driver Packages** by Meta tags assigned to reach package. However, it's recommended to create a proper folder structure to properly organize the individual Driver Packages. For this sample, please create a folder structure as following:

* DriverRepository
  * Core
    * Audio
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

```powershell
cd C:\DriverRepository
```

### Create a Driver Package

As everything in this PowerShell module is built around **Driver Packages**, you must create some.

To be able to create a Driver Package, we first need to have a couple drivers. For this sample, we download the [Intel Graphics Driver for Windows](https://downloadcenter.intel.com/download/27484/Graphics-Intel-Graphics-Driver-for-Windows-15-65-?product=96553). Make sure you select the zip version for download.

Extract the content into **'DriverRepository\Core\Video\Intel\Video Intel 15.65.3.4944 Win10 x64'**. It's helpful to use descriptive names and include information like OS or the version number. It would also be possible to create subfolder per version or whatever structure feels more appropriate.

To allow to easily search for specific Driver Packages, it supports the use of a variety of tag based identifiers. In this sample, we specify the **OSVersion** to be Windows 10 x64 and give it two generic tags of **Core** and **Video**. The process can take some time and is completely silent, like the majority of commands in this module. Most of the commands only return the results. This module makes use of the [PSNLog PowerShell module](https://github.com/MaikKoster/PSNLog) to log more detailed information. To give you a better view on what is actually happening, enable the logging on 'Debug' level. You might want to switch to 'Info' level only later, as it can create a lot of information. For further information about customizing the logging please refer to the [PNSLog project page](https://github.com/MaikKoster/PSNLog). The **-PassThru** parameter will return more information about the Driver Package, that jsut got created and pipe it to the **Format-List** CmdLet to have some easier to read output. Execute the following PowerShell command to scan the drivers in that folder and create a Driver Package:

```powershell
Enable-NLogLogging -FileName '.\Logs\Drivers.log'
New-OSDriverPackage -Path '.\Core\Video\Intel\Video Intel 15.65.3.4944 Win10 x64' -OSVersion 'Win10' -Architecture 'x64' -Tag 'Core', 'Video' -PassThru -Verbose | Format-List
```

Inspect the information about the Driver Package that was returned by the CmdLet. It contains the path to the compressed content (zip file), the path to the Definition file, the **Definition** which contains the tags and some further information that is used for proper filtering later and finally a list of Drivers with some additional information about each.

To have something we can work with, we now need at least a second Driver Package. Preferably one that supports a specific Model. Lets take the [Dell Latitude 5285 Windows 10 Driver Pack](http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12269.latitude-5285-windows-10-driver-pack), but any other will do as well. Assuming the content of the driver pack has been extracted to **'DriverRepository\Model Packages\Dell Latitude 5285 Win10 x64 A05'**, the command to create the Driver Package could now look like the following. As the driver pack contains a lot more drivers, the **-PassThru** parameter is supplied again to actually see what is happening. However not that **Make** and **Model** tags are specified this time. Any structure that make sense can be applied here:

```powershell
New-OSDriverPackage -Path '.\Model Packages\Dell Latitude 5285 Win10 x64 A05' -OSVersion 'Win10' -Architecture 'x64' -Make 'Dell' -Model 'Latitude 5285' -PassThru | Format-List
```

### Compare Driver Packages

Get an instance of each Driver Package that you just created.

```powershell
$CoreVideo = Get-OSDriverPackage -Path '.\Core\Video'

$Dell5285 = Get-OSDriverPackage -Path '.\Model Packages\Dell Latitude 5285 Win10 x64 A05.zip'
```

To compare two Driver Packages, the Compare-OSDriverPackage CmdLet can be used. It takes one or multiple **Core Driver Packages** and compares them against one **Driver Package**. Logic wise, it will go through all the drivers in all the **Core Driver Packages** and check, if the **Driver Package** contains drivers with the same name or the same category and same vendor. For all those that match, it compares the version. If the version in the **Core Driver Package** is the same or higher, it will then compare every **Hardware ID (PnPID)**. If the supported Hardware IDs in the driver from the **Core Driver Package** cover every Hardware ID from the corresponding driver in the **Driver Package**, that particular driver could be replaced. So execute

```powershell
Compare-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285
```

You might wonder that there wasn't any output. The comparison result has actually been added to the original Driver Package. So run the following command to see which Drivers have been identified and can be replaced

```powershell
$Dell5285.Drivers | Where-Object {$_.Replace}
```

The output shows that there is one driver that can be removed from the Driver Package, which is, as expected, a Video driver.

### Remove Drivers from Driver Package

You used the **Compare-OSDriverPackage** CmdLet to get a list of drivers that could be replaced by the **Core Driver Package(s)**. While there are CmdLets available to expand the archive (**Expand-OSDriverPackage**), remove the driver from a **Driver Package** (**Remove-OSDriver**), update the list of drivers (**Read-OSDriverPackage**), and finally create a new archive again (**Compress-OSDriverPackage**), there is a CmdLet that does all this for you in one go. Just call the **Clean-OSDriverPackage** to remove those driver(s) from the **Driver Package**:

```powershell
Clean-OSDriverPackage -CoreDriverPackage $CoreVideo -DriverPackage $Dell5285
```

Check the log file to see the progress and what it is actually doing. At the end of the process, it shows an overview about the difference:

```powershell
DriverPackage  : C:\DriverRepository\Model Packages\Dell Latitude 5285 Win10 x64 A05.zip
OldArchiveSize : 563885860
NewArchiveSize : 305440857
OldFolderSize  : @{Dirs=219; Files=1128; Bytes=1350956352}
NewFolderSize  : @{Dirs=187; Files=840; Bytes=607148888}
OldDriverCount : 116
NewDriverCount : 115
RemovedDrivers : @{...}
```

So we removed 1 driver, related to 32 folders, 288 files and ~709MB in uncompressed size. The compressed Driver Package is now 246MB or 46% smaller.

To do a proper comparison, we would have to compare the total size of the original (expanded) package with the combined size of both archives. Which would result in ~1.2 GB for the uncompressed package and ~612MB for both compressed packages. So while we saved roughly 50% by using the compressed versions, the combined size of both packages is actually slightly larger than the original package from Dell.

However, this was from a single **Core Driver Package** only, that typically covers a broad variety of other models as well. Now adding appropriate **Core Driver Packages** for **Bluetooth**, **Chipset**, **Network**, **Storage**, **Wireless**, etc. and removing the corresponding drivers from multiple Model or Family specific Driver Packages will result in way better ratios. Typical reduction in an enterprise environment with multiple models is about 90-95%.

For sure there is a certain administrative effort related to this approach. So it's important to properly weight the benefits of drastically smaller Driver Packages to the increased amount of administrative effort and complexity. The main purpose of this PowerShell module is to reduce this administrative effort and the complexity, so that this method is usable by a larger audience.

### Apply drivers during deployment

TBD