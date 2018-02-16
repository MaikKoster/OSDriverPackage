function Get-FolderSize {
    <#
    .SYNOPSIS
        Returns the size of a the specified folder.

    .DESCRIPTION
        The Get-FolderSize CmdLet returns the size of the supplied folder.
        It makes use of robocopy to speed up the evaluation of large folder sets.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        # Specifies the path of the folder.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_)})]
        [Alias("FullName")]
        [string]$Path
    )

    begin {
        Write-Verbose "Start getting folder size."
    }
    process {
        try {
            Write-Verbose "  Processing folder '$Path'."

            robocopy /l /nfl /ndl /njh $Path "$($Env:Temp)\VUVWXYZ" /e /bytes |
                Where-Object { $_ -match "^[ \t]+(Dirs|Files|Bytes) :[ ]+\d" } |
                ForEach-Object {
                    if ($_ -like '*Dirs*'){
                        $Dirs = ($_.Trim() -replace 'Dirs : ', '' -replace '[ ]{1,}',',').split(',')[1]
                    } elseif ($_ -like '*Files*'){
                        $Files = ($_.Trim() -replace 'Files : ', '' -replace '[ ]{1,}',',').split(',')[1]
                    } elseif ($_ -like '*Bytes*') {
                        $Bytes = ($_.Trim() -replace 'Bytes : ', '' -replace '[ ]{1,}',',').split(',')[1]
                    }
                }
                Switch ($Bytes) {
                    {$PSItem -le 1KB} {$Size = "$Bytes Bytes)"; Break}
                    {$PSItem -le 1MB} {$Size = "$([Math]::Round($Bytes/1KB, 1)) KBytes)"; Break}
                    {$PSItem -le 1GB} {$Size = "$([Math]::Round($Bytes/1MB,1)) MBytes)"; Break}
                    default {$Size = "$([Math]::Round($Bytes/1GB,1)) GBytes)"; Break}
                }
                Write-Verbose "    Directories: $Dirs, Files: $Files, Size: $Size."
                [PSCustomObject]@{
                    Dirs = $Dirs
                    Files = $Files
                    Bytes = $Bytes
                }
        }catch{$null}
    }
    end {
        Write-Verbose "Finished getting folder size."
    }
}