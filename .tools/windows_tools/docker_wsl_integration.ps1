param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('enable', 'restore')]
    [string]$Action,

    [string]$Distro
)

$ErrorActionPreference = 'Stop'

$dockerSettingsDir = Join-Path $env:APPDATA 'Docker'
$settingsCandidates = @(
    (Join-Path $dockerSettingsDir 'settings-store.json'),
    (Join-Path $dockerSettingsDir 'settings.json')
)

$settingsPath = $settingsCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $settingsPath) {
    Write-Error 'Docker Desktop settings file was not found.'
    exit 10
}

$backupPath = "$settingsPath.dl4mic-backup"

if ($Action -eq 'restore') {
    if (-not (Test-Path -LiteralPath $backupPath)) {
        Write-Error 'Docker Desktop settings backup was not found.'
        exit 11
    }

    Copy-Item -LiteralPath $backupPath -Destination $settingsPath -Force
    Write-Output "Restored Docker Desktop settings from: $backupPath"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Distro)) {
    Write-Error 'A WSL distribution name is required.'
    exit 12
}

try {
    $raw = [System.IO.File]::ReadAllText($settingsPath)
    $settings = $raw | ConvertFrom-Json
} catch {
    Write-Error "Docker Desktop settings could not be read as JSON: $($_.Exception.Message)"
    exit 13
}

# Docker Desktop has used both camelCase and PascalCase keys across releases.
# Preserve whichever spelling is already present; use the current spelling when
# creating the property for the first time.
$integrationProperty = $null
foreach ($candidate in @('integratedWslDistros', 'IntegratedWslDistros')) {
    if ($settings.PSObject.Properties.Name -contains $candidate) {
        $integrationProperty = $candidate
        break
    }
}

if (-not $integrationProperty) {
    $integrationProperty = 'integratedWslDistros'
    $settings | Add-Member -MemberType NoteProperty -Name $integrationProperty -Value @()
}

$current = @($settings.$integrationProperty)

# Refresh the rollback snapshot for every repair attempt, even if this distro is
# already listed. That guarantees a later restore always refers to the settings
# that existed immediately before this attempt, never to an older backup.
Copy-Item -LiteralPath $settingsPath -Destination $backupPath -Force

if ($current -contains $Distro) {
    Write-Output "Docker Desktop settings already include WSL integration for: $Distro"
    Write-Output "Current settings backup saved as: $backupPath"
    exit 0
}

$newDistros = @($current + $Distro | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
$settings.$integrationProperty = $newDistros

try {
    $json = $settings | ConvertTo-Json -Depth 100
    $tempPath = "$settingsPath.dl4mic-temp"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tempPath, $json, $utf8NoBom)

    # Validate the generated JSON before replacing Docker Desktop's file.
    [void]([System.IO.File]::ReadAllText($tempPath) | ConvertFrom-Json)
    Move-Item -LiteralPath $tempPath -Destination $settingsPath -Force
} catch {
    if (Test-Path -LiteralPath $backupPath) {
        Copy-Item -LiteralPath $backupPath -Destination $settingsPath -Force
    }
    Write-Error "Docker Desktop settings could not be updated safely: $($_.Exception.Message)"
    exit 14
}

Write-Output "Enabled Docker Desktop WSL integration setting for: $Distro"
Write-Output "Backup saved as: $backupPath"
exit 0
