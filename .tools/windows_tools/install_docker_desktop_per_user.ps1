[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$termsUrl = 'https://www.docker.com/legal/docker-subscription-service-agreement/'
$tempDir = Join-Path $env:TEMP 'DL4MicEverywhere'
$installerPath = Join-Path $tempDir 'Docker Desktop Installer.exe'
$installLog = Join-Path $env:LOCALAPPDATA 'Docker\install-log.txt'

function Show-DockerConsentDialog {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DL4MicEverywhere - Docker Desktop installation'
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(650, 315)
    $form.TopMost = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Location = New-Object System.Drawing.Point(20, 18)
    $title.Size = New-Object System.Drawing.Size(610, 28)
    $title.Font = New-Object System.Drawing.Font($title.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold)
    $title.Text = 'Docker Desktop is required to run DL4MicEverywhere.'
    $form.Controls.Add($title)

    $body = New-Object System.Windows.Forms.Label
    $body.Location = New-Object System.Drawing.Point(20, 58)
    $body.Size = New-Object System.Drawing.Size(610, 105)
    $body.Text = @(
        'DL4MicEverywhere can install Docker Desktop only for your Windows user account.',
        "The installation uses Docker's WSL 2 backend and does not require Administrator",
        'privileges. Windows containers are disabled because DL4MicEverywhere uses Linux',
        'containers only.',
        '',
        "Docker Desktop is subject to Docker's Subscription Service Agreement."
    ) -join [Environment]::NewLine
    $form.Controls.Add($body)

    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Location = New-Object System.Drawing.Point(20, 170)
    $link.Size = New-Object System.Drawing.Size(610, 24)
    $link.Text = 'Read the Docker Subscription Service Agreement'
    $link.add_LinkClicked({
        try {
            Start-Process $termsUrl | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Could not open the agreement automatically.`r`n`r`n$termsUrl",
                'DL4MicEverywhere',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
    })
    $form.Controls.Add($link)

    $agree = New-Object System.Windows.Forms.CheckBox
    $agree.Location = New-Object System.Drawing.Point(20, 205)
    $agree.Size = New-Object System.Drawing.Size(610, 42)
    $agree.Text = 'I have read and agree to the Docker Subscription Service Agreement.'
    $form.Controls.Add($agree)

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(350, 265)
    $installButton.Size = New-Object System.Drawing.Size(135, 32)
    $installButton.Text = 'Agree and Install'
    $installButton.Enabled = $false
    $installButton.add_Click({
        $form.Tag = 'install'
        $form.Close()
    })
    $form.Controls.Add($installButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(495, 265)
    $cancelButton.Size = New-Object System.Drawing.Size(135, 32)
    $cancelButton.Text = 'Cancel'
    $cancelButton.add_Click({
        $form.Tag = 'cancel'
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    $agree.add_CheckedChanged({
        $installButton.Enabled = $agree.Checked
    })

    [void]$form.ShowDialog()
    return ($form.Tag -eq 'install')
}

if (-not (Show-DockerConsentDialog)) {
    Write-Host 'Docker Desktop installation was cancelled by the user.'
    exit 2
}

$nativeArch = if ($env:PROCESSOR_ARCHITEW6432) {
    $env:PROCESSOR_ARCHITEW6432
} else {
    $env:PROCESSOR_ARCHITECTURE
}

switch ($nativeArch.ToUpperInvariant()) {
    'AMD64' {
        $downloadUrl = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'
    }
    'ARM64' {
        $downloadUrl = 'https://desktop.docker.com/win/main/arm64/Docker%20Desktop%20Installer.exe'
    }
    default {
        Write-Host "ERROR: Unsupported Windows architecture for automatic Docker Desktop installation: $nativeArch" -ForegroundColor Red
        exit 13
    }
}

try {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue

    # Windows PowerShell 5.1 can otherwise negotiate older TLS defaults on some
    # systems. Docker's download endpoint requires HTTPS; force TLS 1.2 when the
    # enum is available without changing any machine-wide configuration.
    if ([enum]::GetNames([Net.SecurityProtocolType]) -contains 'Tls12') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Write-Host 'Downloading Docker Desktop from Docker official servers...'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Write-Host "ERROR: Docker Desktop download failed: $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
    exit 10
}

try {
    Write-Host 'Verifying Docker Desktop installer signature...'
    $signature = Get-AuthenticodeSignature -FilePath $installerPath
    $subject = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { '' }

    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or
        [string]::IsNullOrWhiteSpace($subject) -or
        $subject -notmatch '(?i)Docker') {
        Write-Host "ERROR: Docker Desktop installer signature validation failed. Status: $($signature.Status); signer: $subject" -ForegroundColor Red
        Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
        exit 11
    }

    Write-Host "Verified installer signer: $subject"
} catch {
    Write-Host "ERROR: Docker Desktop installer signature could not be validated: $($_.Exception.Message)" -ForegroundColor Red
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
    exit 11
}

try {
    Write-Host 'Installing Docker Desktop for the current Windows user...'
    $arguments = @(
        'install',
        '--user',
        '--backend=wsl-2',
        '--accept-license',
        '--no-windows-containers'
    )

    $process = Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Host "ERROR: Docker Desktop installer returned exit code $($process.ExitCode)." -ForegroundColor Red
        if (Test-Path -LiteralPath $installLog) {
            Write-Host "Docker installer log: $installLog"
        }
        exit 12
    }
} catch {
    Write-Host "ERROR: Docker Desktop installation failed: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path -LiteralPath $installLog) {
        Write-Host "Docker installer log: $installLog"
    }
    exit 12
} finally {
    Remove-Item -LiteralPath $installerPath -Force -ErrorAction SilentlyContinue
}

Write-Host 'Docker Desktop per-user installation completed successfully.'
exit 0
