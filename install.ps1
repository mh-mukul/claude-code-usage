# install.ps1 — one-line installer for claude-usage on Windows.
#
#   iwr -useb <repo-raw>/install.ps1 | iex
#
# Env overrides:
#   $env:VERSION   = 'v0.1.0'                 # pin to a tagged release
#   $env:REPO_URL  = 'https://github.com/...'
#   $env:INSTALL_DIR = "$env:LOCALAPPDATA\Programs\claude-usage"

$ErrorActionPreference = 'Stop'

# ── Config ──────────────────────────────────────────────────────────────────
$RepoUrl    = if ($env:REPO_URL)    { $env:REPO_URL }    else { 'https://github.com/mhmukul/claude-code-usage' }
$Version    = if ($env:VERSION)     { $env:VERSION }     else { 'main' }
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { "$env:LOCALAPPDATA\Programs\claude-usage" }
$ScriptName = 'claude-usage'

# Derive raw URL.
$RawUrl = $null
if ($RepoUrl -match '^https://github.com/(.+)$') {
    $RawUrl = "https://raw.githubusercontent.com/$($matches[1])/$Version/claude-usage.py"
} elseif ($RepoUrl -match '^https://gitlab') {
    $RawUrl = "$RepoUrl/-/raw/$Version/claude-usage.py"
} else {
    throw "Unrecognized REPO_URL host. Set REPO_URL to a github.com or gitlab.* URL."
}

# ── 1. Detect Python 3.9+ ───────────────────────────────────────────────────
$Python = $null
foreach ($cmd in @('py -3', 'python', 'python3')) {
    try {
        $parts = $cmd -split ' '
        $exe   = $parts[0]
        $args  = if ($parts.Length -gt 1) { $parts[1..($parts.Length-1)] } else { @() }
        $check = & $exe @args -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)' 2>$null
        if ($LASTEXITCODE -eq 0) { $Python = $cmd; break }
    } catch { continue }
}

if (-not $Python) {
    Write-Host "Python 3.9+ required. Install via:" -ForegroundColor Red
    Write-Host "  winget install Python.Python.3.11"
    Write-Host "  ...or download from https://www.python.org/downloads/"
    throw "Python missing."
}

Write-Host "Found Python via: $Python"

# ── 2. Ensure install dir ───────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# ── 3. Download claude-usage.py ─────────────────────────────────────────────
$Dest    = Join-Path $InstallDir 'claude-usage.py'
$CmdShim = Join-Path $InstallDir "$ScriptName.cmd"

Write-Host "Downloading $RawUrl"
Write-Host "  → $Dest"

try {
    Invoke-WebRequest -UseBasicParsing -Uri $RawUrl -OutFile $Dest
} catch {
    throw "Download failed: $_"
}

# Sanity: must start with shebang or python script comment
$firstLine = Get-Content -Path $Dest -TotalCount 1
if (-not ($firstLine -match '^(#!|"""|\#)')) {
    Remove-Item $Dest
    throw "Downloaded file does not look like a Python script. Aborting."
}

# ── 4. Generate .cmd shim so users can type 'claude-usage' anywhere ─────────
$shimBody = "@echo off`r`n$Python `"%~dp0claude-usage.py`" %*`r`n"
Set-Content -Path $CmdShim -Value $shimBody -Encoding ASCII -NoNewline

# ── 5. PATH check ───────────────────────────────────────────────────────────
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$InstallDir*") {
    Write-Host ""
    Write-Host "WARN: $InstallDir is not on your user PATH." -ForegroundColor Yellow
    Write-Host "Add it via:"
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', `"`$env:Path;$InstallDir`", 'User')"
    Write-Host "Or open a new shell after adding the directory in System Properties."
}

# ── 6. Hint ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "claude-usage installed." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  $ScriptName dashboard         # scan + open browser"
Write-Host "  $ScriptName today             # terminal table"
Write-Host "  $ScriptName --help"
Write-Host ""
Write-Host "Data lives in $env:USERPROFILE\.claude\usage.db"
Write-Host "Uninstall: powershell -ExecutionPolicy Bypass -File uninstall.ps1"
