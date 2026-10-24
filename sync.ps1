# Reverse of install.ps1: pulls convention hooks edited directly in
# ~/.claude/hooks back INTO this repo (plugins/conventions/hooks), and the
# status line from ~/.claude/statusline into statusline/, so in-place tweaks
# aren't lost. Review with `git diff` before committing.
#
# Only the manually-installed hooks are synced. Plugin contents (planning,
# review, etc.) are managed by the marketplace, not file copy, and are not
# synced here.
#
# Usage (from the repo root):   powershell -ExecutionPolicy Bypass -File .\sync.ps1

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$src  = Join-Path $env:USERPROFILE '.claude/hooks'
$dest = Join-Path $repo 'plugins/conventions/hooks'

$statusLine = Join-Path $env:USERPROFILE '.claude/statusline'

if (-not (Test-Path $src) -and -not (Test-Path $statusLine)) {
    Write-Host "Nothing to sync: neither $src nor $statusLine exists."
    exit 0
}

Write-Host "Syncing convention hooks from $src into $dest"
Write-Host "(Overwrites repo copies. Review with git diff before committing.)"
foreach ($sub in @('cross-platform', 'windows-only')) {
    $from = Join-Path $src $sub
    if (-not (Test-Path $from)) { continue }
    $to = Join-Path $dest $sub
    New-Item -ItemType Directory -Force -Path $to | Out-Null
    Copy-Item -Path (Join-Path $from '*') -Destination $to -Recurse -Force
    Write-Host "  pulled hooks/$sub/"
}

foreach ($f in @('statusline.sh', 'statusline.ps1')) {
    $from = Join-Path $statusLine $f
    if (-not (Test-Path $from)) { continue }
    Copy-Item -Path $from -Destination (Join-Path $repo "statusline/$f") -Force
    Write-Host "  pulled statusline/$f"
}

Write-Host ""
Write-Host "Done. Now: git status / git diff, then commit manually."
Write-Host "If you changed the American-English word map in the .ps1, regenerate"
Write-Host "the .sh map (see plugins/conventions/hooks/README.md)."
