# Installs the convention HOOKS into ~/.claude on Windows for the manual /
# PowerShell wiring path (the always-on, no-Git-Bash-needed setup).
#
# Everything else in debussy now ships as plugins installed via the marketplace:
#   /plugin marketplace add Oire/debussy
#   /plugin install planning@debussy   (and review, write-manual, dotnet-tools)
# The convention hooks are also available as the 'conventions' plugin (bash/.sh
# path). Use THIS script only if you prefer the native PowerShell runners wired
# through settings.json.
#
# Copies plugins/conventions/hooks/* into ~/.claude/hooks/, preserving the
# cross-platform/ and windows-only/ subdirectories. Does NOT touch settings.json.
#
# Usage (from the repo root):   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$src  = Join-Path $repo 'plugins/conventions/hooks'
$dest = Join-Path $env:USERPROFILE '.claude/hooks'

Write-Host "Installing convention hooks into $dest"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dest -Recurse -Force -Exclude 'hooks.json'

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Merge the hooks block from settings\settings.windows.example.json"
Write-Host "     into $env:USERPROFILE\.claude\settings.json (under hooks.PreToolUse)."
Write-Host "  2. Restart Claude Code (or run /hooks) so the hooks load."
Write-Host ""
Write-Host "Features (planning, review, write-manual, dotnet-tools) install via"
Write-Host "the marketplace: /plugin marketplace add Oire/debussy"
