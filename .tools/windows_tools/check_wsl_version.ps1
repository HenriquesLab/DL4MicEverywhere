[CmdletBinding()]
param(
    [version]$MinimumVersion = [version]'2.1.5'
)

$ErrorActionPreference = 'Stop'

try {
    $output = & wsl.exe --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        exit 1
    }

    $text = ($output | Out-String)
    $match = [regex]::Match($text, '\d+\.\d+\.\d+(?:\.\d+)?')
    if (-not $match.Success) {
        exit 1
    }

    $version = [version]$match.Value
    Write-Host "      WSL version: $version"

    if ($version -lt $MinimumVersion) {
        exit 2
    }

    exit 0
} catch {
    exit 1
}
