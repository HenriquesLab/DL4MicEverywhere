[CmdletBinding()]
param(
    [string]$Distribution = 'Ubuntu-24.04'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Exit-code contract used by Windows_launch.bat:
#   0  = Ubuntu is installed and uses WSL 2
#   2  = user cancelled the installation
#   10 = distribution not found in the WSL online catalog
#   11 = WSL installation command failed, including the --web-download retry
#   12 = Windows must restart before Ubuntu can be registered (not scheduled)
#   14 = Ubuntu is installed but could not be configured as WSL 2
#   15 = unexpected helper failure
#   20 = Windows restart was scheduled successfully

. "$PSScriptRoot\wsl_common.ps1"

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
        'After installation, DL4MicEverywhere will ask you to choose the Ubuntu username',
        'and Ubuntu itself will securely prompt you for that account password.'
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
        # When Windows components such as Virtual Machine Platform were not yet
        # enabled, `wsl --install` enables them and reports success, but the
        # distribution can only be registered after a Windows restart. The WSL
        # output that says so is localized, so rely only on "success + not registered".
        Write-Host ''
        Write-Host "WSL enabled the Windows components it needs. Windows must restart before $Distribution can be installed." -ForegroundColor Yellow
        $restartResult = Request-WindowsRestart
        exit $restartResult
    }

    # Do not inherit a machine's previous default WSL generation. DL4MicEverywhere
    # requires WSL 2. Current WSL versions already register new distributions as
    # WSL 2, and `wsl --set-version` then fails with "already the requested
    # version", so only convert when the distribution is not WSL 2 yet, and
    # judge the result by querying WSL again rather than by the exit code.
    if ((Get-WslDistributionGeneration -Distro $Distribution) -ne 0) {
        Write-Host "Ensuring $Distribution uses WSL 2..."
        & wsl.exe --set-version $Distribution 2
        $setVersionResult = $LASTEXITCODE
        if ((Get-WslDistributionGeneration -Distro $Distribution) -ne 0) {
            Write-Host "ERROR: Could not configure $Distribution as WSL 2. Exit code: $setVersionResult" -ForegroundColor Red
            exit 14
        }
    }

    Write-Host ''
    Write-Host "$Distribution has been installed successfully." -ForegroundColor Green
    Write-Host 'DL4MicEverywhere will now create the normal Ubuntu user with your input.'
    Write-Host 'The Windows launcher will ask you to choose the Linux username and Ubuntu will'
    Write-Host 'collect the password directly, including after an interrupted fresh installation.'
    Write-Host ''
    exit 0
} catch {
    Write-Host "ERROR: Unexpected Ubuntu installation failure: $($_.Exception.Message)" -ForegroundColor Red
    exit 15
}
