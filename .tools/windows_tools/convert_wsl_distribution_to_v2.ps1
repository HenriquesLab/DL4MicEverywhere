[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Distribution
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\wsl_common.ps1"

try {
    Add-Type -AssemblyName System.Windows.Forms

    $message = @(
        "$Distribution is currently registered as WSL 1.",
        '',
        'DL4MicEverywhere requires WSL 2 for Docker Desktop integration.',
        'Would you like DL4MicEverywhere to convert this distribution to WSL 2 now?',
        '',
        'The conversion uses Microsoft''s official `wsl --set-version` command and',
        'preserves the distribution files. It can take some time on large distributions.'
    ) -join [Environment]::NewLine

    $choice = [System.Windows.Forms.MessageBox]::Show(
        $message,
        'DL4MicEverywhere - Convert Ubuntu to WSL 2',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )

    if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host 'WSL 2 conversion was cancelled by the user.'
        exit 2
    }

    Write-Host "Converting $Distribution to WSL 2..."
    & wsl.exe --set-version $Distribution 2
    $setVersionResult = $LASTEXITCODE
    # `wsl --set-version` can return an error even when the distribution is
    # already WSL 2 ("already the requested version"), so query WSL again.
    if ((Get-WslDistributionGeneration -Distro $Distribution) -ne 0) {
        Write-Host "ERROR: WSL conversion returned exit code $setVersionResult." -ForegroundColor Red
        exit 10
    }

    Write-Host "$Distribution is now configured for WSL 2." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "ERROR: Could not convert $Distribution to WSL 2: $($_.Exception.Message)" -ForegroundColor Red
    exit 10
}
