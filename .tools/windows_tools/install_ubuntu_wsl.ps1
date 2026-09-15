[CmdletBinding()]
param(
    [string]$Distribution = 'Ubuntu-24.04'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Normalize-WslDistributionName {
    param([AllowNull()][string]$Name)

    if ($null -eq $Name) {
        return ''
    }

    $normalized = $Name.Replace([string][char]0, '')
    $normalized = $normalized.TrimStart([char]0xFEFF)
    return $normalized.Trim()
}

function Show-UbuntuConsentDialog {
    param([Parameter(Mandatory = $true)][string]$Distro)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DL4MicEverywhere - Ubuntu installation'
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(650, 285)
    $form.TopMost = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Location = New-Object System.Drawing.Point(20, 18)
    $title.Size = New-Object System.Drawing.Size(610, 28)
    $title.Font = New-Object System.Drawing.Font($title.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold)
    $title.Text = 'An Ubuntu WSL distribution is required to run DL4MicEverywhere.'
    $form.Controls.Add($title)

    $body = New-Object System.Windows.Forms.Label
    $body.Location = New-Object System.Drawing.Point(20, 58)
    $body.Size = New-Object System.Drawing.Size(610, 145)
    $body.Text = @(
        "DL4MicEverywhere can install $Distro using Microsoft's official WSL installer.",
        '',
        'WSL itself is already installed. This step only downloads and registers the Ubuntu',
        'distribution for your Windows user account; it does not enable Windows optional',
        'features or change the default distribution used by other applications.',
        '',
        'After installation, Ubuntu will ask you once to create a Linux username and password.'
    ) -join [Environment]::NewLine
    $form.Controls.Add($body)

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(350, 230)
    $installButton.Size = New-Object System.Drawing.Size(135, 32)
    $installButton.Text = 'Install Ubuntu'
    $installButton.add_Click({
        $form.Tag = 'install'
        $form.Close()
    })
    $form.Controls.Add($installButton)
    $form.AcceptButton = $installButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(495, 230)
    $cancelButton.Size = New-Object System.Drawing.Size(135, 32)
    $cancelButton.Text = 'Cancel'
    $cancelButton.add_Click({
        $form.Tag = 'cancel'
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    [void]$form.ShowDialog()
    return ($form.Tag -eq 'install')
}

function Test-DistributionListed {
    param([Parameter(Mandatory = $true)][string]$Distro)

    $installed = & wsl.exe --list --quiet 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    return [bool]($installed |
        ForEach-Object { Normalize-WslDistributionName -Name $_ } |
        Where-Object { $_ -ieq $Distro })
}

function Test-DistributionAvailableOnline {
    param([Parameter(Mandatory = $true)][string]$Distro)

    $online = & wsl.exe --list --online 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    # Friendly names and headers may be localized, but the installation token
    # itself (for example Ubuntu-24.04) is stable and can be matched verbatim.
    return [bool]($online | Where-Object { $_ -match "(?i)(^|\s)$([regex]::Escape($Distro))(\s|$)" })
}

function Invoke-WslInstall {
    param(
        [Parameter(Mandatory = $true)][string]$Distro,
        [switch]$WebDownload
    )

    $arguments = @('--install', '--distribution', $Distro, '--no-launch')
    if ($WebDownload) {
        $arguments += '--web-download'
    }

    & wsl.exe @arguments | ForEach-Object { Write-Host $_ }
    $exitCode = $LASTEXITCODE
    return $exitCode
}

function Ask-WebDownloadRetry {
    Add-Type -AssemblyName System.Windows.Forms

    $result = [System.Windows.Forms.MessageBox]::Show(
        @(
            'The normal WSL Ubuntu installation did not complete successfully.',
            '',
            'Would you like DL4MicEverywhere to retry using WSL''s --web-download mode?',
            'This downloads the distribution from Microsoft''s online WSL source instead of',
            'using the normal Microsoft Store-backed path.'
        ) -join [Environment]::NewLine,
        'DL4MicEverywhere - Retry Ubuntu installation',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

try {
    if (Test-DistributionListed -Distro $Distribution) {
        Write-Host "$Distribution is already installed."
        exit 0
    }

    Write-Host "Checking that $Distribution is available from WSL..."
    if (-not (Test-DistributionAvailableOnline -Distro $Distribution)) {
        Write-Host "ERROR: $Distribution was not found in the WSL online distribution catalog." -ForegroundColor Red
        exit 10
    }

    if (-not (Show-UbuntuConsentDialog -Distro $Distribution)) {
        Write-Host 'Ubuntu installation was cancelled by the user.'
        exit 2
    }

    Write-Host "Installing $Distribution using Microsoft's WSL installer..."
    $installResult = Invoke-WslInstall -Distro $Distribution

    if ($installResult -ne 0) {
        Write-Host "The normal WSL installation returned exit code $installResult." -ForegroundColor Yellow

        if (-not (Ask-WebDownloadRetry)) {
            exit 11
        }

        Write-Host "Retrying $Distribution installation using --web-download..."
        $installResult = Invoke-WslInstall -Distro $Distribution -WebDownload
        if ($installResult -ne 0) {
            Write-Host "ERROR: WSL --web-download installation returned exit code $installResult." -ForegroundColor Red
            exit 11
        }
    }

    if (-not (Test-DistributionListed -Distro $Distribution)) {
        Write-Host "ERROR: WSL reported a successful installation, but $Distribution is not registered." -ForegroundColor Red
        exit 12
    }

    # Do not inherit a machine's previous default WSL generation. DL4MicEverywhere
    # requires WSL 2, so configure the newly installed distro explicitly before
    # first-run user creation. This changes only this distribution.
    Write-Host "Ensuring $Distribution uses WSL 2..."
    & wsl.exe --set-version $Distribution 2
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Could not configure $Distribution as WSL 2. Exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 14
    }

    Write-Host ''
    Write-Host "$Distribution has been installed successfully." -ForegroundColor Green
    Write-Host ''
    Write-Host 'Ubuntu now needs to perform its standard one-time Linux user setup.'
    Write-Host 'Create the requested Linux username and password.'
    Write-Host 'When the Ubuntu shell appears after setup, type:'
    Write-Host ''
    Write-Host '    exit' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'DL4MicEverywhere will then continue automatically.'
    Write-Host ''

    & wsl.exe --distribution $Distribution
    $firstRunResult = $LASTEXITCODE
    if ($firstRunResult -ne 0) {
        Write-Host "ERROR: The first Ubuntu launch returned exit code $firstRunResult." -ForegroundColor Red
        exit 13
    }

    # Confirm that the distribution can start after first-run initialization.
    & wsl.exe --distribution $Distribution --user root --cd / --exec /bin/true
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'ERROR: Ubuntu is installed but could not be started after its initial setup.' -ForegroundColor Red
        exit 13
    }

    Write-Host "$Distribution initial setup completed successfully." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "ERROR: Unexpected Ubuntu installation failure: $($_.Exception.Message)" -ForegroundColor Red
    exit 15
}
