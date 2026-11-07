# Shared helpers for the WSL installation scripts. Dot-source this file:
#   . "$PSScriptRoot\wsl_common.ps1"

# Ask whether to restart Windows now. Returns the launcher exit codes:
#   12 = restart still required (declined or could not be scheduled)
#   20 = Windows restart was scheduled successfully
function Request-WindowsRestart {
    Add-Type -AssemblyName System.Windows.Forms

    $result = [System.Windows.Forms.MessageBox]::Show(
        @(
            'Windows needs to restart before WSL 2 is ready.',
            '',
            'Restart Windows now?',
            '',
            'After Windows restarts, run Windows_launch.bat again. The launcher will',
            'continue with the automatic Ubuntu and Docker Desktop setup.'
        ) -join [Environment]::NewLine,
        'DL4MicEverywhere - Windows restart required',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        return 12
    }

    try {
        & shutdown.exe /r /t 0 /c 'DL4MicEverywhere WSL installation completed. Restarting Windows to apply WSL 2 changes.'
        if ($LASTEXITCODE -eq 0) {
            return 20
        }
    } catch {}

    return 12
}

# Return the WSL generation of a registered distribution using the exit codes of
# check_wsl_distribution_version.ps1: 0 = WSL 2, 2 = WSL 1, 3 = not found,
# 4/10 = query or parse failure.
function Get-WslDistributionGeneration {
    param([Parameter(Mandatory = $true)][string]$Distro)

    & "$PSScriptRoot\check_wsl_distribution_version.ps1" -Distribution $Distro
    return $LASTEXITCODE
}
