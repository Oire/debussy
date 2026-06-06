# Removes the manually-installed convention hooks from ~/.claude/hooks on
# Windows. Deletes only the files this repo installs, by explicit name -- it
# will NOT touch other hooks you may keep there. Does NOT edit settings.json;
# remove the hooks block yourself (see the printed reminder).
#
# Plugins (planning, review, write-manual, dotnet-tools, conventions) are
# removed via:  /plugin uninstall <name>@debussy
#
# Usage (from the repo root):   powershell -ExecutionPolicy Bypass -File .\uninstall.ps1

$ErrorActionPreference = 'Stop'

$hooks = Join-Path $env:USERPROFILE '.claude/hooks'
$files = @(
    'cross-platform/check-american-english.ps1',
    'cross-platform/check-american-english.sh',
    'cross-platform/check-git-guard.ps1',
    'cross-platform/check-git-guard.sh',
    'windows-only/check-no-null-redirect.ps1'
)
foreach ($f in $files) {
    $p = Join-Path $hooks $f
    if (Test-Path $p) { Remove-Item -Force $p; Write-Host "  removed hooks/$f" }
}

Write-Host ""
Write-Host "Done. Manual follow-ups:"
Write-Host "  - Remove the debussy hooks block from your ~/.claude/settings.json."
Write-Host "  - Plugins are removed via: /plugin uninstall <name>@debussy"
