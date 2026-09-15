[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Install', 'Update')]
    [string]$Operation,

    [version]$MinimumVersion = [version]'2.1.5'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Exit-code contract used by Windows_launch.bat:
#   0  = WSL is ready and meets MinimumVersion
#   2  = user cancelled the consent/UAC flow
#   10 = Microsoft WSL install/update command failed, including fallback
#   11 = wsl.exe is unavailable on this Windows version
#   12 = operation completed but Windows restart is still required/not scheduled
#   13 = operation completed but WSL still does not meet MinimumVersion
#   14 = unexpected helper failure
#   20 = Windows restart was scheduled successfully

function Show-WslConsentDialog {
    param([Parameter(Mandatory = $true)][string]$RequestedOperation)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $isInstall = ($RequestedOperation -eq 'Install')
    $verb = if ($isInstall) { 'install' } else { 'update' }
    $titleVerb = if ($isInstall) { 'installation' } else { 'update' }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DL4MicEverywhere - WSL $titleVerb"
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(680, 315)
    $form.TopMost = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Location = New-Object System.Drawing.Point(20, 18)
    $title.Size = New-Object System.Drawing.Size(640, 28)
    $title.Font = New-Object System.Drawing.Font($title.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold)
    $title.Text = if ($isInstall) {
        'Windows Subsystem for Linux (WSL) is required to run DL4MicEverywhere.'
    } else {
        'Windows Subsystem for Linux (WSL) needs to be updated.'
    }
    $form.Controls.Add($title)

    $body = New-Object System.Windows.Forms.Label
    $body.Location = New-Object System.Drawing.Point(20, 58)
    $body.Size = New-Object System.Drawing.Size(640, 160)
    $body.Text = if ($isInstall) {
        @(
            'DL4MicEverywhere can use Microsoft''s official WSL installer to enable/install',
            'the required Windows WSL components. Ubuntu is installed separately afterwards.',
            '',
            'Windows may need Administrator permission because WSL 2 relies on machine-level',
            'Windows virtualization components. Only the Microsoft WSL installation command',
            'will be elevated; DL4MicEverywhere itself continues as your normal Windows user.',
            '',
            'A Windows restart may be required after installation.'
        ) -join [Environment]::NewLine
    } else {
        @(
            "DL4MicEverywhere requires WSL $MinimumVersion or later for Docker Desktop.",
            'It can run Microsoft''s official WSL update command automatically.',
            '',
            'The update is attempted first as your normal Windows user. If Windows requires',
            'Administrator permission, only the Microsoft WSL update command is elevated;',
            'DL4MicEverywhere itself continues as your normal user.',
            '',
            'A Windows restart may be required if Windows is still using older WSL components.'
        ) -join [Environment]::NewLine
    }
    $form.Controls.Add($body)

    $continueButton = New-Object System.Windows.Forms.Button
    $continueButton.Location = New-Object System.Drawing.Point(370, 260)
    $continueButton.Size = New-Object System.Drawing.Size(140, 32)
    $continueButton.Text = if ($isInstall) { 'Install WSL' } else { 'Update WSL' }
    $continueButton.add_Click({
        $form.Tag = 'continue'
        $form.Close()
    })
    $form.Controls.Add($continueButton)
    $form.AcceptButton = $continueButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(520, 260)
    $cancelButton.Size = New-Object System.Drawing.Size(140, 32)
    $cancelButton.Text = 'Cancel'
    $cancelButton.add_Click({
        $form.Tag = 'cancel'
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    [void]$form.ShowDialog()
    return ($form.Tag -eq 'continue')
}

function Get-CurrentWslVersion {
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

function Invoke-WslCurrentUser {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    try {
        & wsl.exe @Arguments
        return $LASTEXITCODE
    } catch {
        return 1
    }
}

function Invoke-ElevatedWsl {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $wslPath = Join-Path $env:SystemRoot 'System32\wsl.exe'
    if (-not (Test-Path -LiteralPath $wslPath)) {
        $command = Get-Command wsl.exe -ErrorAction SilentlyContinue
        if ($null -eq $command) {
            return 9001
        }
        $wslPath = $command.Source
    }

    try {
        $process = Start-Process -FilePath $wslPath `
            -ArgumentList $Arguments `
            -Verb RunAs `
            -Wait `
            -PassThru
        return $process.ExitCode
    } catch [System.ComponentModel.Win32Exception] {
        # ERROR_CANCELLED (1223) is the normal result when the user declines UAC.
        if ($_.Exception.NativeErrorCode -eq 1223) {
            return 1223
        }
        throw
    }
}

function Ask-WebDownloadRetry {
    param([Parameter(Mandatory = $true)][string]$RequestedOperation)

    Add-Type -AssemblyName System.Windows.Forms
    $verb = if ($RequestedOperation -eq 'Install') { 'installation' } else { 'update' }

    $result = [System.Windows.Forms.MessageBox]::Show(
        @(
            "The normal WSL $verb did not complete successfully.",
            '',
            'Would you like DL4MicEverywhere to retry using Microsoft WSL''s',
            '--web-download mode instead of the normal Store-backed download path?'
        ) -join [Environment]::NewLine,
        "DL4MicEverywhere - Retry WSL $verb",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    return ($result -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Request-WindowsRestart {
    Add-Type -AssemblyName System.Windows.Forms

    $result = [System.Windows.Forms.MessageBox]::Show(
        @(
            'Windows needs to restart before WSL 2 is ready.',
            '',
            'Restart Windows now?',
            '',
            'After Windows restarts, run Windows_launch.bat again. The launcher will',
            'continue with the automatic Ubuntu and Docker Desktop setup.'
        ) -join [Environment]::NewLine,
        'DL4MicEverywhere - Windows restart required',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        return 12
    }

    try {
        & shutdown.exe /r /t 0 /c 'DL4MicEverywhere WSL installation completed. Restarting Windows to apply WSL 2 changes.'
        if ($LASTEXITCODE -eq 0) {
            return 20
        }
    } catch {}

    return 12
}

try {
    if (-not (Show-WslConsentDialog -RequestedOperation $Operation)) {
        Write-Host "WSL $($Operation.ToLowerInvariant()) was cancelled by the user."
        exit 2
    }

    if ($Operation -eq 'Install') {
        $arguments = @('--install', '--no-distribution')
    } else {
        $arguments = @('--update')
    }

    if ($Operation -eq 'Update') {
        Write-Host "Trying Microsoft's WSL update as the current Windows user..."
        $result = Invoke-WslCurrentUser -Arguments $arguments
        if ($result -ne 0) {
            Write-Host "The non-elevated WSL update returned exit code $result. Retrying with Administrator permission..." -ForegroundColor Yellow
            $result = Invoke-ElevatedWsl -Arguments $arguments
        }
    } else {
        Write-Host "Running Microsoft's WSL installation command with Administrator permission..."
        $result = Invoke-ElevatedWsl -Arguments $arguments
    }

    if ($result -eq 1223) {
        Write-Host 'Administrator permission was cancelled by the user.'
        exit 2
    }
    if ($result -eq 9001) {
        Write-Host 'ERROR: wsl.exe is unavailable on this Windows version.' -ForegroundColor Red
        exit 11
    }

    # Windows Installer conventions use 3010 for success with reboot required
    # and 1641 when a restart has already been initiated. Treat both as a
    # successful prerequisite change rather than retrying the download path.
    if ($result -in @(3010, 1641)) {
        $restartResult = Request-WindowsRestart
        exit $restartResult
    }

    if ($result -ne 0) {
        Write-Host "The normal WSL command returned exit code $result." -ForegroundColor Yellow

        if (-not (Ask-WebDownloadRetry -RequestedOperation $Operation)) {
            exit 10
        }

        $retryArguments = @($arguments + '--web-download')
        Write-Host 'Retrying through WSL --web-download...'
        $result = Invoke-ElevatedWsl -Arguments $retryArguments

        if ($result -eq 1223) {
            Write-Host 'Administrator permission was cancelled by the user.'
            exit 2
        }
        if ($result -eq 9001) {
            Write-Host 'ERROR: wsl.exe is unavailable on this Windows version.' -ForegroundColor Red
            exit 11
        }
        if ($result -in @(3010, 1641)) {
            $restartResult = Request-WindowsRestart
            exit $restartResult
        }
        if ($result -ne 0) {
            Write-Host "ERROR: WSL --web-download returned exit code $result." -ForegroundColor Red
            exit 10
        }
    }

    # An update can leave already-running WSL processes on the previous runtime.
    # Shut them down before verifying the installed WSL package version. Ignore
    # failures here because a machine with no registered distro may have nothing
    # to shut down yet.
    if ($Operation -eq 'Update') {
        try { & wsl.exe --shutdown 2>$null } catch {}
        Start-Sleep -Milliseconds 750
    }

    $version = Get-CurrentWslVersion
    if ($null -ne $version) {
        Write-Host "WSL version after $($Operation.ToLowerInvariant()): $version"
        if ($version -ge $MinimumVersion) {
            Write-Host 'WSL is ready for DL4MicEverywhere.' -ForegroundColor Green
            exit 0
        }

        Write-Host "WSL is still older than required version $MinimumVersion." -ForegroundColor Yellow
        exit 13
    }

    # A successful first-time WSL install commonly needs a Windows restart when
    # optional virtualization components have just been enabled. Offer that step
    # directly instead of misreporting the installation as a version failure.
    if ($Operation -eq 'Install') {
        $restartResult = Request-WindowsRestart
        exit $restartResult
    }

    # Updating a legacy inbox WSL installation can also require Windows to reload
    # its components. Offer the same restart before declaring the update unusable.
    $restartResult = Request-WindowsRestart
    exit $restartResult
} catch {
    Write-Host "ERROR: Unexpected WSL $($Operation.ToLowerInvariant()) failure: $($_.Exception.Message)" -ForegroundColor Red
    exit 14
}
