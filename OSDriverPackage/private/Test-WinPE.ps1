# Helper function to check if the current system is running WinPE
function Test-WinPE {
    [CmdLetBinding()]
    param()
    $Result = $false
    try {
        $MiniNT = Get-Item -Path HKLM:\SYSTEM\ControlSet001\Control\MiniNT -ErrorAction SilentlyContinue
        if ($null -ne $MiniNT) {
            $Result = $true
        }
    } catch {}

    $Result
}