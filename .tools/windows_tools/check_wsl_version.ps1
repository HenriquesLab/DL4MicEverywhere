[CmdletBinding()]
param(
    [version]$MinimumVersion = [version]'2.1.5'
)

$ErrorActionPreference = 'Stop'

# Exit-code contract used by Windows_launch.bat:
#   0 = modern WSL is installed and meets MinimumVersion
#   1 = unexpected detection failure
#   2 = WSL is present but legacy/outdated and should be updated
#   3 = no operational WSL runtime is installed/ready

function Get-WslVersion {
    try {
        $output = & wsl.exe --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        $text = ($output | Out-String).Replace([string][char]0, '')
        $match = [regex]::Match($text, '\d+\.\d+\.\d+(?:\.\d+)?')
        if (-not $match.Success) {
            return $null
        }

        return [version]$match.Value
    } catch {
        return $null
    }
}

function Test-LegacyWslRuntime {
    # Older inbox WSL versions may not implement `wsl --version` even though the
    # optional Windows components are enabled and usable. Distinguish that state
    # from the Windows wsl.exe stub being present while WSL itself is not ready.
    try {
        & wsl.exe --status *> $null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {}

    try {
        & wsl.exe --list --quiet *> $null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {}

    return $false
}

try {
    $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($null -eq $wslCommand) {
        Write-Host '      WSL runtime: not installed.'
        exit 3
    }

    $version = Get-WslVersion
    if ($null -ne $version) {
        Write-Host "      WSL version: $version"

        if ($version -lt $MinimumVersion) {
            exit 2
        }

        exit 0
    }

    if (Test-LegacyWslRuntime) {
        Write-Host '      WSL runtime: legacy/outdated installation detected.'
        exit 2
    }

    Write-Host '      WSL runtime: not installed or not yet enabled.'
    exit 3
} catch {
    Write-Host "      WSL detection failed: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 1
}
