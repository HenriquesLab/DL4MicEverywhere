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

function Test-SafeLinuxUserName {
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    # Ubuntu's normal first-run usernames are simple ASCII account names. Keep
    # this strict because the value is returned to cmd.exe and used as a token.
    return ($Name -match '^[A-Za-z_][A-Za-z0-9_.-]*\$?$')
}

function Test-LinuxUser {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Test-SafeLinuxUserName -Name $Name)) {
        return $false
    }

    $uidOutput = & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/bin/id -u $Name 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $uidText = Normalize-WslText -Text (($uidOutput | Select-Object -First 1) -as [string])
    $uid = 0
    if (-not [int]::TryParse($uidText, [ref]$uid)) {
        return $false
    }

    # DL4MicEverywhere must not run as root. Do not assume the account is UID
    # 1000: WSL installations can legitimately create the first usable account
    # with another UID (for example 1001).
    return ($uid -gt 0)
}

function Get-ConfiguredDefaultUser {
    $configLines = & wsl.exe --distribution $Distribution --user root --cd / --exec /bin/cat /etc/wsl.conf 2>$null
    if ($LASTEXITCODE -ne 0) {
        return ''
    }

    $inUserSection = $false
    foreach ($rawLine in $configLines) {
        $line = Normalize-WslText -Text ($rawLine -as [string])
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line.StartsWith('#') -or $line.StartsWith(';')) {
            continue
        }

        $sectionMatch = [regex]::Match($line, '^\[\s*([^\]]+)\s*\]$')
        if ($sectionMatch.Success) {
            $inUserSection = ($sectionMatch.Groups[1].Value.Trim() -ieq 'user')
            continue
        }

        if (-not $inUserSection) {
            continue
        }

        $defaultMatch = [regex]::Match($line, '^(?i:default)\s*=\s*(.+?)\s*$')
        if (-not $defaultMatch.Success) {
            continue
        }

        $candidate = $defaultMatch.Groups[1].Value.Trim()
        if ($candidate.Length -ge 2 -and
            (($candidate[0] -eq '"' -and $candidate[$candidate.Length - 1] -eq '"') -or
             ($candidate[0] -eq "'" -and $candidate[$candidate.Length - 1] -eq "'"))) {
            $candidate = $candidate.Substring(1, $candidate.Length - 2).Trim()
        }
        return $candidate
    }

    return ''
}

function Get-RegularHomeUsers {
    $passwdLines = & wsl.exe --distribution $Distribution --user root --cd / --exec /bin/cat /etc/passwd 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not read /etc/passwd from the Ubuntu distribution.'
    }

    $users = New-Object System.Collections.Generic.List[string]
    foreach ($rawLine in $passwdLines) {
        $line = Normalize-WslText -Text ($rawLine -as [string])
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line.Split(':')
        if ($parts.Count -lt 7) {
            continue
        }

        $name = $parts[0]
        $uid = 0
        if (-not [int]::TryParse($parts[2], [ref]$uid)) {
            continue
        }
        $home = $parts[5]
        $shell = $parts[6]

        if ($uid -lt 1000 -or $uid -ge 65534) {
            continue
        }
        if (-not $home.StartsWith('/home/')) {
            continue
        }
        if ($shell -match '(?i)/(nologin|false|sync)$') {
            continue
        }
        if (-not (Test-SafeLinuxUserName -Name $name)) {
            continue
        }

        $users.Add($name)
    }

    return @($users | Sort-Object -Unique)
}

try {
    $configuredUser = Get-ConfiguredDefaultUser
    if (-not [string]::IsNullOrWhiteSpace($configuredUser) -and (Test-LinuxUser -Name $configuredUser)) {
        Write-Output $configuredUser
        exit 0
    }

    # If /etc/wsl.conf has no usable [user] default, fall back only when there
    # is exactly one normal /home account. Never guess between multiple users.
    $regularUsers = @(Get-RegularHomeUsers)
    if ($regularUsers.Count -eq 1 -and (Test-LinuxUser -Name $regularUsers[0])) {
        Write-Output $regularUsers[0]
        exit 0
    }

    # Keep the absence of any regular account distinct from an ambiguous or
    # inconsistent existing-user state. The Windows launcher can safely resume
    # Ubuntu's one-time OOBE only when no regular account exists at all.
    if ($regularUsers.Count -eq 0) {
        exit 2
    }

    exit 3
} catch {
    exit 10
}
