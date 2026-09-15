[CmdletBinding()]
param(
    [string]$PreferredDistribution = 'Ubuntu-24.04'
)

$ErrorActionPreference = 'Stop'

function Normalize-WslDistributionName {
    param([AllowNull()][string]$Name)

    if ($null -eq $Name) {
        return ''
    }

    # Depending on the Windows/WSL combination, redirected `wsl --list --quiet`
    # output can contain embedded NULs or a Unicode BOM.  Those characters are
    # invisible in cmd.exe but make an otherwise correct distribution name fail
    # when passed back to wsl.exe.
    $normalized = $Name.Replace([string][char]0, '')
    $normalized = $normalized.TrimStart([char]0xFEFF)
    return $normalized.Trim()
}

try {
    $rawDistributions = & wsl.exe --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        exit 10
    }

    $distributions = @(
        $rawDistributions |
            ForEach-Object { Normalize-WslDistributionName -Name $_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $preferred = $distributions |
        Where-Object { $_ -ieq $PreferredDistribution } |
        Select-Object -First 1

    if ($preferred) {
        Write-Output $preferred
        exit 0
    }

    $fallback = $distributions |
        Where-Object { $_ -match '(?i)^Ubuntu(?:$|-[0-9].*)' } |
        Select-Object -First 1

    if ($fallback) {
        Write-Output $fallback
        exit 0
    }

    # No supported Ubuntu distribution is installed.  This is not an error for
    # the launcher; it is the signal that automatic installation should run.
    exit 2
} catch {
    exit 10
}
