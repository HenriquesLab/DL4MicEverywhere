[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Distribution
)

$ErrorActionPreference = 'Stop'

function Normalize-WslText {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ''
    }

    $normalized = $Text.Replace([string][char]0, '')
    $normalized = $normalized.TrimStart([char]0xFEFF)
    return $normalized.Trim()
}

try {
    $target = Normalize-WslText -Text $Distribution
    if ([string]::IsNullOrWhiteSpace($target)) {
        exit 3
    }

    # Microsoft documents `wsl --list --verbose` as the authoritative way to
    # inspect whether each registered distribution is running as WSL 1 or WSL 2.
    # Normalize every line because redirected WSL output can contain NUL/BOM
    # characters on some Windows/WSL combinations.
    $lines = & wsl.exe --list --verbose 2>$null
    if ($LASTEXITCODE -ne 0) {
        exit 10
    }

    foreach ($rawLine in $lines) {
        $line = Normalize-WslText -Text $rawLine
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # The default distribution is marked with a leading '*'. Remove only
        # that marker; it is not part of the registered distribution name.
        if ($line.StartsWith('*')) {
            $line = $line.Substring(1).TrimStart()
        }

        # The final two columns are STATE and VERSION. We intentionally do not
        # depend on localized column headers. Official Ubuntu WSL names used by
        # DL4MicEverywhere contain no whitespace, so the first token is the exact
        # distribution name and the final token is the WSL generation.
        $parts = @($line -split '\s+' | Where-Object { $_ -ne '' })
        if ($parts.Count -lt 3) {
            continue
        }

        $name = $parts[0]
        $version = $parts[$parts.Count - 1]

        if ($name -ieq $target) {
            if ($version -eq '2') {
                exit 0
            }
            if ($version -eq '1') {
                exit 2
            }
            exit 4
        }
    }

    exit 3
} catch {
    exit 10
}
