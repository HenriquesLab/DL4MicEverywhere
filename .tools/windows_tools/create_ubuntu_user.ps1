[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Distribution
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Normalize-WslText {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ''
    }

    $normalized = $Text.Replace([string][char]0, '')
    $normalized = $normalized.TrimStart([char]0xFEFF)
    return $normalized.Trim()
}

function Test-SafeDistributionName {
    param([AllowNull()][string]$Name)
    return (-not [string]::IsNullOrWhiteSpace($Name) -and $Name -match '^[A-Za-z0-9._-]+$')
}

function Test-SafeLinuxUserName {
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    # Keep newly-created accounts within Ubuntu/Debian's conventional username
    # subset. This also makes every later native invocation safe as a token.
    return ($Name -match '^[a-z_][a-z0-9_-]{0,31}$')
}

function Invoke-WslQuiet {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & wsl.exe @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output)
    }
}

function Get-RegularHomeUsers {
    $result = Invoke-WslQuiet -Arguments @(
        '--distribution', $Distribution,
        '--user', 'root',
        '--cd', '/',
        '--exec', '/bin/cat', '/etc/passwd'
    )
    if ($result.ExitCode -ne 0) {
        throw 'Could not read /etc/passwd from Ubuntu.'
    }

    $users = New-Object System.Collections.Generic.List[string]
    foreach ($rawLine in $result.Output) {
        $line = Normalize-WslText -Text ($rawLine -as [string])
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line.Split(':')
        if ($parts.Count -lt 7) {
            continue
        }

        $uid = 0
        if (-not [int]::TryParse($parts[2], [ref]$uid)) {
            continue
        }

        $name = $parts[0]
        $linuxHomeDirectory = $parts[5]
        $shell = $parts[6]

        if ($uid -lt 1000 -or $uid -ge 65534) {
            continue
        }
        if (-not $linuxHomeDirectory.StartsWith('/home/')) {
            continue
        }
        if ($shell -match '(?i)/(nologin|false|sync)$') {
            continue
        }

        $users.Add($name)
    }

    return @($users | Sort-Object -Unique)
}

function Get-SuggestedUserName {
    $candidate = ($env:USERNAME -as [string])
    if ($null -eq $candidate) {
        $candidate = ''
    }
    $candidate = $candidate.ToLowerInvariant()
    $candidate = [regex]::Replace($candidate, '[^a-z0-9_-]', '-')
    $candidate = $candidate.Trim('-')

    if ($candidate.Length -gt 32) {
        $candidate = $candidate.Substring(0, 32)
    }
    if (-not (Test-SafeLinuxUserName -Name $candidate)) {
        return 'dl4meuser'
    }
    return $candidate
}

function Read-NewUserName {
    $suggested = Get-SuggestedUserName

    while ($true) {
        Write-Host ''
        Write-Host 'Choose the Linux username you want to use inside Ubuntu.' -ForegroundColor Cyan
        Write-Host 'Use lowercase letters, numbers, underscore, or hyphen.'
        $entered = Read-Host "Ubuntu username [$suggested]"
        if ([string]::IsNullOrWhiteSpace($entered)) {
            $entered = $suggested
        }
        $entered = $entered.Trim()

        if (-not (Test-SafeLinuxUserName -Name $entered)) {
            Write-Host 'That username is not valid. Example: ihidalgo' -ForegroundColor Yellow
            continue
        }

        $idResult = Invoke-WslQuiet -Arguments @(
            '--distribution', $Distribution,
            '--user', 'root',
            '--cd', '/',
            '--exec', '/usr/bin/id', '-u', $entered
        )
        if ($idResult.ExitCode -eq 0) {
            Write-Host "The Linux account '$entered' already exists. Choose another username." -ForegroundColor Yellow
            continue
        }

        $groupResult = Invoke-WslQuiet -Arguments @(
            '--distribution', $Distribution,
            '--user', 'root',
            '--cd', '/',
            '--exec', '/usr/bin/getent', 'group', $entered
        )
        if ($groupResult.ExitCode -eq 0) {
            Write-Host "A Linux group named '$entered' already exists. Choose another username." -ForegroundColor Yellow
            continue
        }

        return $entered
    }
}

function Remove-NewUserBestEffort {
    param([Parameter(Mandatory = $true)][string]$User)

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/sbin/userdel -r $User 2>$null | Out-Null
        & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/sbin/groupdel $User 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Set-WslDefaultUser {
    param([Parameter(Mandatory = $true)][string]$User)

    $readResult = Invoke-WslQuiet -Arguments @(
        '--distribution', $Distribution,
        '--user', 'root',
        '--cd', '/',
        '--exec', '/bin/cat', '/etc/wsl.conf'
    )

    $sourceLines = @()
    if ($readResult.ExitCode -eq 0) {
        $sourceLines = @($readResult.Output | ForEach-Object { ($_ -as [string]).Replace([string][char]0, '').TrimEnd("`r") })
    }

    $output = New-Object System.Collections.Generic.List[string]
    $inUserSection = $false
    $userSectionSeen = $false
    $defaultWritten = $false

    foreach ($line in $sourceLines) {
        $sectionMatch = [regex]::Match($line, '^\s*\[\s*([^\]]+)\s*\]\s*$')
        if ($sectionMatch.Success) {
            if ($inUserSection -and -not $defaultWritten) {
                $output.Add("default=$User")
                $defaultWritten = $true
            }

            $inUserSection = ($sectionMatch.Groups[1].Value.Trim() -ieq 'user')
            if ($inUserSection) {
                $userSectionSeen = $true
            }
            $output.Add($line)
            continue
        }

        if ($inUserSection -and $line -match '^\s*(?i:default)\s*=') {
            if (-not $defaultWritten) {
                $output.Add("default=$User")
                $defaultWritten = $true
            }
            continue
        }

        $output.Add($line)
    }

    if ($inUserSection -and -not $defaultWritten) {
        $output.Add("default=$User")
        $defaultWritten = $true
    }

    if (-not $userSectionSeen) {
        if ($output.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($output[$output.Count - 1])) {
            $output.Add('')
        }
        $output.Add('[user]')
        $output.Add("default=$User")
    }

    $content = (($output -join "`n").TrimEnd("`r", "`n")) + "`n"

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'wsl.exe'
    $startInfo.Arguments = "--distribution $Distribution --user root --cd / --exec /usr/bin/tee /etc/wsl.conf"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'Could not start WSL to update /etc/wsl.conf.'
    }

    $process.StandardInput.Write($content)
    $process.StandardInput.Close()
    $null = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "Could not set Ubuntu's default user in /etc/wsl.conf. $stderr"
    }
}

function Stop-WslDistributionBestEffort {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe --terminate $Distribution 2>$null | Out-Null
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

try {
    if (-not (Test-SafeDistributionName -Name $Distribution)) {
        Write-Host 'ERROR: The Ubuntu distribution name is not safe to pass to WSL.' -ForegroundColor Red
        exit 10
    }

    $existingUsers = @(Get-RegularHomeUsers)
    if ($existingUsers.Count -gt 0) {
        Write-Host 'Ubuntu already contains one or more regular Linux users:' -ForegroundColor Yellow
        foreach ($existingUser in $existingUsers) {
            Write-Host "  $existingUser"
        }
        Write-Host 'DL4MicEverywhere will not create another account automatically in this state.' -ForegroundColor Yellow
        exit 3
    }

    Write-Host ''
    Write-Host 'Ubuntu is installed, but it does not have a normal Linux user yet.' -ForegroundColor Yellow
    Write-Host 'DL4MicEverywhere will create one now using the username you choose.'
    Write-Host 'The account will have its own home directory and sudo access.'
    Write-Host 'Your password will be entered directly into Ubuntu and is not stored by DL4MicEverywhere.'

    $user = Read-NewUserName

    Write-Host ''
    Write-Host "Creating Ubuntu account '$user'..."

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/sbin/useradd -m -U -s /bin/bash $user
        $createExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($createExitCode -ne 0) {
        Write-Host "ERROR: Ubuntu could not create the account '$user' (exit code $createExitCode)." -ForegroundColor Red
        exit 11
    }

    Write-Host ''
    Write-Host 'Set the password for this Ubuntu account.' -ForegroundColor Cyan
    Write-Host 'Ubuntu will ask for the new password twice. The characters will not be displayed.'
    Write-Host ''

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/bin/passwd $user
        $passwdExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($passwdExitCode -ne 0) {
        Write-Host ''
        Write-Host 'Password setup did not complete. Removing the incomplete Ubuntu account.' -ForegroundColor Yellow
        Remove-NewUserBestEffort -User $user
        if ($passwdExitCode -eq 130) {
            exit 2
        }
        exit 12
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe --distribution $Distribution --user root --cd / --exec /usr/sbin/usermod -aG sudo $user
        $sudoExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($sudoExitCode -ne 0) {
        Write-Host "ERROR: Could not grant sudo access to '$user'. Removing the incomplete account." -ForegroundColor Red
        Remove-NewUserBestEffort -User $user
        exit 13
    }

    try {
        Set-WslDefaultUser -User $user
    } catch {
        # The launcher always invokes Ubuntu explicitly with -u <user>, so the
        # account remains usable even if the convenience default cannot be set.
        # Do not destroy a fully-created user just because wsl.conf could not be
        # updated; discovery will still find this sole /home account.
        Write-Host "WARNING: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "DL4MicEverywhere can still use '$user' explicitly." -ForegroundColor Yellow
    }

    Stop-WslDistributionBestEffort
    Start-Sleep -Milliseconds 500

    $validation = Invoke-WslQuiet -Arguments @(
        '--distribution', $Distribution,
        '--user', $user,
        '--cd', "/home/$user",
        '--exec', '/usr/bin/id', '-u'
    )

    if ($validation.ExitCode -ne 0) {
        Write-Host "ERROR: The new Ubuntu account '$user' was created but could not be started." -ForegroundColor Red
        exit 14
    }

    $uidText = Normalize-WslText -Text (($validation.Output | Select-Object -First 1) -as [string])
    $uid = 0
    if (-not [int]::TryParse($uidText, [ref]$uid) -or $uid -le 0) {
        Write-Host "ERROR: Ubuntu returned an invalid UID for '$user'." -ForegroundColor Red
        exit 14
    }

    Write-Host ''
    Write-Host "Ubuntu account '$user' is ready (UID $uid)." -ForegroundColor Green
    Write-Output $user
    exit 0
} catch {
    Write-Host "ERROR: Could not create the Ubuntu user account: $($_.Exception.Message)" -ForegroundColor Red
    exit 15
}
