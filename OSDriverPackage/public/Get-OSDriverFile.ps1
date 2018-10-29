function Get-OSDriverFile {
    <#
    .SYNOPSIS
        Finds specified driver files.

    .DESCRIPTION
        Finds specified driver files.
        Optionally all directories containing these files can be removed.

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ByDriverPackage')]
    [OutputType([object[]])]
    param (
        # Specifies the Driver Package
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ParameterSetName='ByDriverPackage')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path -Path $_.DriverPath) -or (Test-Path -Path $_.DriverArchiveFile)})]
        [PSCustomObject]$DriverPackage,

        # Specifies the path where to search for driver files
        [Parameter(Mandatory, Position=0, ValueFromPipelineByPropertyName, ParameterSetName='ByPath')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
        [Alias("FullName")]
        [string]$Path,

        # Specifies the name of the drivers files.
        # The name can include wildcards. Default is '*.inf'
        [string]$Files = '*.inf'
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
            $script:Logger.Trace("Get driver files ('Path':'$Path', 'Files':'$Files'")
        } else {
            $script:Logger.Trace("Get driver files ('DriverPackage':'$($DriverPackage.DefinitionFile)', 'Files':'$Files'")
        }

        if ($null -ne $DriverPackage) {
            if (Test-Path -Path $DriverPackage.DriverPath) {
                $Path = $DriverPackage.DriverPath
            } else {
                $Path = $DriverPackage.DriverArchiveFile
            }
        }

        if ($Path -match '\.cab|\.zip') {
            $script:Logger.Debug('Temporarily expanding content of Driver Package.')
            $Expanded = $true
            $Path = Expand-Folder -Path $Path
        } else {
            $Expanded = $false
        }

        $script:Logger.Info("Get driver files from '$Path'.")
        $DriverFiles = @(Get-ChildItem -Path $Path -Recurse -File -Filter $Files)

        if ($Expanded) {
            $script:Logger.Debug('Removing temporary content.')
            Remove-Item -Path $Path -Recurse -Force
        }

        $DriverFiles
    }
}