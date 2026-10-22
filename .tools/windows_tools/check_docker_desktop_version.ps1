[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DockerExe,

    # TODO: set this to the Docker Desktop version confirmed by the Windows GPU
    # tester (older versions failed GPU passthrough with WSL 2 and newer NVIDIA
    # libraries). 0.0.0 disables the warning until the value is confirmed.
    [version]$MinimumVersion = [version]'0.0.0'
)

$ErrorActionPreference = 'Stop'

# Exit-code contract used by Windows_launch.bat:
#   0 = continue (version is fine, unknown, not relevant, or the user chose to continue)
#   2 = the user chose to stop and update Docker Desktop first
#
# This check never updates Docker Desktop itself: updates are done by the user
# from Docker Desktop (per-user installations update without administrator
# rights). It only matters for GPU use, so it is skipped without an NVIDIA GPU.

function Test-NvidiaGpuPresent {
    $nvidiaSmi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if ($null -eq $nvidiaSmi) {
        return $false
    }
    try {
        & $nvidiaSmi.Source *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Get-DockerDesktopVersion {
    try {
        $platform = & $DockerExe version --format '{{.Server.Platform.Name}}' 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        $match = [regex]::Match(($platform | Out-String), 'Docker Desktop\s+(\d+\.\d+\.\d+)')
        if (-not $match.Success) {
            return $null
        }
        return [version]$match.Groups[1].Value
    } catch {
        return $null
    }
}

try {
    if ($MinimumVersion -le [version]'0.0.0') {
        exit 0
    }
    if (-not (Test-NvidiaGpuPresent)) {
        exit 0
    }

    $version = Get-DockerDesktopVersion
    if ($null -eq $version) {
        exit 0
    }
    Write-Host "      Docker Desktop version: $version"
    if ($version -ge $MinimumVersion) {
        exit 0
    }

    Add-Type -AssemblyName System.Windows.Forms
    $choice = [System.Windows.Forms.MessageBox]::Show(
        @(
            "Docker Desktop $version is older than $MinimumVersion.",
            '',
            'GPU acceleration may not work with this version (older Docker Desktop',
            'releases can fail to pass the NVIDIA GPU through to WSL 2). CPU use is not affected.',
            '',
            'To update: open Docker Desktop and choose "Check for updates".',
            'DL4MicEverywhere does not update Docker Desktop automatically.',
            '',
            'Continue with the current version?'
        ) -join [Environment]::NewLine,
        'DL4MicEverywhere - Docker Desktop update recommended',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($choice -eq [System.Windows.Forms.DialogResult]::No) {
        exit 2
    }
    exit 0
} catch {
    # The version warning is advisory; never block the launcher on it.
    exit 0
}
