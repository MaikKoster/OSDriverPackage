@{

    # Script module or binary module file associated with this manifest
    RootModule = 'OSDriverPackage.psm1'

    # Version number of this module.
    ModuleVersion = '0.1.0'

    # ID used to uniquely identify this module
    GUID = '882400f5-c8c3-430f-a454-17eaec20a708'

    # Author of this module
    Author = 'Maik Koster'

    # Company or vendor of this module
    CompanyName = ''

    # Copyright statement for this module
    Copyright = '(c) 2018 Maik Koster. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Powershell Module to handle the tooling around Driver Package management'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Name of the Windows PowerShell host required by this module
    #PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    #PowerShellHostVersion = ''

    # Minimum version of the .NET Framework required by this module
    # DotNetFrameworkVersion = '2.0'

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = '2.0.50727'

    # Processor architecture (None, X86, Amd64, IA64) required by this module
    #ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules = @('PSNLog')

    # Assemblies that must be loaded prior to importing this module
    #RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to
    # importing this module
    #ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    #TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    #FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in
    # ModuleToProcess
    #NestedModules = @()

    # Functions to export from this module
    #FunctionsToExport = @()

    # Cmdlets to export from this module
    #CmdletsToExport = @()

    # Variables to export from this module
    #VariablesToExport = @()

    # Aliases to export from this module
    #AliasesToExport = @()

    # List of all modules packaged with this module
    #ModuleList = @()

    # List of all files packaged with this module
    #FileList = @()

    # Private data to pass to the module specified in ModuleToProcess
    PrivateData = @{
        PSData = @{

                # Tags applied to this module. These help with module discovery in online galleries.
                Tags = 'OSD','MDT','Driver Management'

                # A URL to the license for this module.
                LicenseUri = 'https://github.com/MaikKoster/OSDriverPackage/blob/master/LICENSE'

                # A URL to the main website for this project.
                ProjectUri = 'https://github.com/MaikKoster/OSDriverPackage'

                # A URL to an icon representing this module.
                # IconUri = ''

                # ReleaseNotes of this module
                # ReleaseNotes = ''

                # External dependent modules of this module
                # ExternalModuleDependencies = ''
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'http://github.com/MaikKoster/OSDriverPackage/blob/master/OSDriverPackage/en-US/'
}