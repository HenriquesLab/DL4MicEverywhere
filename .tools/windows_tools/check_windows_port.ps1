[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 65535)]
    [int]$Port
)

$ErrorActionPreference = 'Stop'

try {
    # Query the Windows TCP table directly. This catches listeners created by
    # native Windows applications (for example a Windows Jupyter server) that
    # are invisible to netstat/ss inside WSL.
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    if ($listeners | Where-Object { $_.Port -eq $Port } | Select-Object -First 1) {
        exit 1
    }

    exit 0
} catch {
    Write-Error "Could not inspect Windows TCP listeners for port ${Port}: $($_.Exception.Message)"
    exit 2
}
