# Reverse of install.ps1: pulls convention hooks edited directly in
# ~/.claude/hooks back INTO this repo (plugins/conventions/hooks), so in-place
# tweaks aren't lost. Review with `git diff` before committing.
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

if (-not (Test-Path $src)) { Write-Host "Nothing to sync: $src does not exist."; exit 0 }

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

Write-Host ""
Write-Host "Done. Now: git status / git diff, then commit manually."
Write-Host "If you changed the American-English word map in the .ps1, regenerate"
Write-Host "the .sh map (see plugins/conventions/hooks/README.md)."
