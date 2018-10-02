# Helper function to return the SCCM TS environment
# returns $null if TSEnvironment doesn't exist or if the amount of variables is to low.
function Get-TSEnvironment {
    [CmdLetBinding()]
    param()
    try {
        $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    } catch {}

    if ($null -ne $TSEnv) {
        if ($TSEnv.GetVariables().Count -le 1) {
            $TSEnv = $Null
        }
    }

    $TSEnv
}