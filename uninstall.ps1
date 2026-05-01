# uninstall.ps1 — remove claude-code-usage on Windows.
#
# Pass -Purge to also delete the local database.

[CmdletBinding()]
param(
    [switch]$Purge
)

$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { "$env:LOCALAPPDATA\Programs\claude-code-usage" }

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "Removed $InstallDir"
} else {
    Write-Host "Not installed at $InstallDir"
}

if ($Purge) {
    $Db = Join-Path $env:USERPROFILE '.claude\usage.db'
    if (Test-Path $Db) {
        Remove-Item -Force $Db
        Write-Host "Purged $Db"
    }
}

Write-Host "Done."
