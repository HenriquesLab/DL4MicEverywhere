param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('timed', 'direct')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [int]$TimeoutMilliseconds = 30000,

    [string]$StdoutPath = (Join-Path $env:TEMP 'dl4me_wsl_probe_stdout.txt'),
    [string]$StderrPath = (Join-Path $env:TEMP 'dl4me_wsl_probe_stderr.txt')
)

$ErrorActionPreference = 'Stop'

try {
    Remove-Item -LiteralPath $StdoutPath, $StderrPath -Force -ErrorAction SilentlyContinue
} catch {
    # Stale diagnostic files are non-critical.
}

if ([string]::IsNullOrWhiteSpace($Distro)) {
    'The WSL distribution name is empty.' | Out-File -LiteralPath $StderrPath -Encoding utf8
    exit 3
}

if ($Action -eq 'direct') {
    try {
        # Pass every argument natively. This mirrors a normal interactive WSL
        # command and avoids Start-Process command-line reconstruction entirely.
        & wsl.exe --distribution $Distro --user root --exec /bin/true 1> $StdoutPath 2> $StderrPath
        if ($LASTEXITCODE -eq 0) { exit 0 }
        exit 1
    } catch {
        $_ | Out-File -LiteralPath $StderrPath -Encoding utf8
        exit 3
    }
}

try {
    # Start-Process ultimately receives a single native command line. Microsoft
    # recommends supplying one ArgumentList string; build it explicitly here.
    if ($Distro -match '[\s"]') {
        $escapedDistro = $Distro.Replace('"', '\"')
        $distroToken = '"' + $escapedDistro + '"'
    } else {
        $distroToken = $Distro
    }

    $arguments = "--distribution $distroToken --user root --exec /bin/true"

    $process = Start-Process -FilePath 'wsl.exe' `
        -ArgumentList $arguments `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $StdoutPath `
        -RedirectStandardError $StderrPath

    if ($process.WaitForExit($TimeoutMilliseconds)) {
        if ($process.ExitCode -eq 0) { exit 0 }
        exit 1
    }

    try { $process.Kill() } catch {}
    exit 2
} catch {
    $_ | Out-File -LiteralPath $StderrPath -Encoding utf8
    exit 3
}
