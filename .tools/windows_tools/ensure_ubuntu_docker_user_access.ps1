[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Distribution,

    [Parameter(Mandatory = $true)]
    [string]$User
)

$ErrorActionPreference = 'Stop'

function Test-SafeLinuxUserName {
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    return ($Name -match '^[A-Za-z_][A-Za-z0-9_.-]*\$?$')
}

function Invoke-WslQuiet {
    param(
        [Parameter(Mandatory = $true)][string]$RunAs,
        [Parameter(Mandatory = $true)][string[]]$Command
    )

    $arguments = @('--distribution', $Distribution, '--user', $RunAs, '--cd', '/', '--exec') + $Command

    # A failed native command is an expected diagnostic result here. In Windows
    # PowerShell, native stderr can be promoted to an ErrorRecord; with the
    # script-wide ErrorActionPreference=Stop that can terminate the helper before
    # we get a chance to inspect LASTEXITCODE. Temporarily downgrade error action
    # only around wsl.exe, while still keeping Stop for PowerShell/.NET failures.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & wsl.exe @arguments *> $null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return $exitCode
}

function Invoke-WslCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RunAs,
        [Parameter(Mandatory = $true)][string[]]$Command
    )

    $arguments = @('--distribution', $Distribution, '--user', $RunAs, '--cd', '/', '--exec') + $Command

    # As above, a non-zero Linux exit code is data, not a PowerShell exception.
    # Suppress native stderr for capture probes and decide from LASTEXITCODE.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & wsl.exe @arguments 2>$null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($exitCode -ne 0) {
        return $null
    }

    $text = (($output | ForEach-Object { $_ -as [string] }) -join "`n")
    if ($null -eq $text) {
        return ''
    }

    return $text.Replace([string][char]0, '').TrimStart([char]0xFEFF).Trim()
}

function Test-DockerAccess {
    param([Parameter(Mandatory = $true)][string]$RunAs)

    $result = Invoke-WslQuiet -RunAs $RunAs -Command @('/usr/bin/env', 'docker', 'info')
    return ($result -eq 0)
}

function Show-DockerAccessConsentDialog {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'DL4MicEverywhere - Docker access in Ubuntu'
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ClientSize = New-Object System.Drawing.Size(675, 315)
    $form.TopMost = $true

    $title = New-Object System.Windows.Forms.Label
    $title.Location = New-Object System.Drawing.Point(20, 18)
    $title.Size = New-Object System.Drawing.Size(635, 28)
    $title.Font = New-Object System.Drawing.Font($title.Font.FontFamily, 11, [System.Drawing.FontStyle]::Bold)
    $title.Text = 'Docker Desktop is running, but your Ubuntu user cannot access Docker.'
    $form.Controls.Add($title)

    $body = New-Object System.Windows.Forms.Label
    $body.Location = New-Object System.Drawing.Point(20, 58)
    $body.Size = New-Object System.Drawing.Size(635, 185)
    $body.Text = @(
        "Docker works as root inside $Distribution, so the Docker Desktop engine and WSL integration are healthy.",
        '',
        "The Linux account '$User' is not a member of the 'docker' group that owns the Docker socket.",
        'DL4MicEverywhere can add this Ubuntu account to that group and then verify Docker access again.',
        '',
        'This changes only the Linux account inside this WSL distribution and does not require Windows',
        'Administrator permission. Membership in the docker group grants control of the Docker daemon,',
        'which is a privileged capability inside the Linux environment.'
    ) -join [Environment]::NewLine
    $form.Controls.Add($body)

    $grantButton = New-Object System.Windows.Forms.Button
    $grantButton.Location = New-Object System.Drawing.Point(355, 262)
    $grantButton.Size = New-Object System.Drawing.Size(145, 32)
    $grantButton.Text = 'Grant Docker Access'
    $grantButton.add_Click({
        $form.Tag = 'grant'
        $form.Close()
    })
    $form.Controls.Add($grantButton)
    $form.AcceptButton = $grantButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(510, 262)
    $cancelButton.Size = New-Object System.Drawing.Size(145, 32)
    $cancelButton.Text = 'Cancel'
    $cancelButton.add_Click({
        $form.Tag = 'cancel'
        $form.Close()
    })
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    [void]$form.ShowDialog()
    return ($form.Tag -eq 'grant')
}

try {
    if (-not (Test-SafeLinuxUserName -Name $User)) {
        Write-Host "ERROR: Unsafe or invalid Ubuntu username: $User" -ForegroundColor Red
        exit 10
    }

    # The desired state is Docker working directly as the normal Linux account.
    if (Test-DockerAccess -RunAs $User) {
        exit 0
    }

    # If root cannot use Docker either, this is an integration/engine problem,
    # not a per-user permission problem. Let the launcher show its integration help.
    if (-not (Test-DockerAccess -RunAs 'root')) {
        exit 3
    }

    # Docker Desktop for Windows exposes its WSL engine through /var/run/docker.sock.
    # Only repair the standard root:docker, group-writable case. Never broaden socket
    # permissions and never add the user to an unrelated privileged group such as root.
    $socketType = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/stat', '-Lc', '%F', '/var/run/docker.sock')
    $socketGroup = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/stat', '-Lc', '%G', '/var/run/docker.sock')
    $socketMode = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/stat', '-Lc', '%a', '/var/run/docker.sock')

    if ($socketType -ne 'socket' -or $socketGroup -ne 'docker') {
        Write-Host 'Docker works as root, but the Docker socket is not the standard root:docker socket.' -ForegroundColor Yellow
        if (-not [string]::IsNullOrWhiteSpace($socketType)) {
            Write-Host "Socket type: $socketType"
        }
        if (-not [string]::IsNullOrWhiteSpace($socketGroup)) {
            Write-Host "Socket group: $socketGroup"
        }
        if (-not [string]::IsNullOrWhiteSpace($socketMode)) {
            Write-Host "Socket mode: $socketMode"
        }
        exit 4
    }

    $dockerGroup = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/getent', 'group', 'docker')
    if ([string]::IsNullOrWhiteSpace($dockerGroup)) {
        Write-Host "Docker socket uses group 'docker', but that group could not be resolved in $Distribution." -ForegroundColor Yellow
        exit 4
    }

    $currentGroups = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/id', '-nG', $User)
    $groupNames = @($currentGroups -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($groupNames -contains 'docker') {
        # A fresh WSL process already receives supplementary groups. If Docker still
        # fails here, changing group membership again would hide a different problem.
        Write-Host "$User is already in the docker group, but Docker access still fails." -ForegroundColor Yellow
        exit 4
    }

    if (-not (Show-DockerAccessConsentDialog)) {
        Write-Host 'Docker access for the Ubuntu user was not changed.'
        exit 2
    }

    Write-Host "Adding $User to the docker group inside $Distribution..."
    $modifyResult = Invoke-WslQuiet -RunAs 'root' -Command @('/usr/sbin/usermod', '-aG', 'docker', $User)
    if ($modifyResult -ne 0) {
        Write-Host "ERROR: Could not add $User to the docker group. Exit code: $modifyResult" -ForegroundColor Red
        exit 10
    }

    # Every wsl.exe invocation below creates a fresh Linux process, so supplementary
    # group membership is recalculated without requiring a Windows sign-out/reboot.
    $updatedGroups = Invoke-WslCapture -RunAs 'root' -Command @('/usr/bin/id', '-nG', $User)
    if (-not (@($updatedGroups -split '\s+') -contains 'docker')) {
        Write-Host "ERROR: $User was not found in the docker group after usermod completed." -ForegroundColor Red
        exit 10
    }

    if (-not (Test-DockerAccess -RunAs $User)) {
        Write-Host "Docker access is still unavailable for $User after adding the docker group." -ForegroundColor Yellow
        exit 4
    }

    Write-Host "Docker access is ready for Ubuntu user $User." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "ERROR: Unexpected Docker user-access check failure: $($_.Exception.Message)" -ForegroundColor Red
    exit 10
}
