#!/usr/bin/env bash
# Removes the manually-installed convention hooks from ~/.claude/hooks on
# Linux/macOS/WSL. Deletes only the files this repo installs, by explicit name
# -- it will NOT touch other hooks you may keep there. Does NOT edit
# settings.json; remove the hooks block yourself (see the printed reminder).
#
# Plugins (planning, review, write-manual, dotnet-tools, conventions) are
# removed via:  /plugin uninstall <name>@debussy
#
# Usage (from the repo root):   bash uninstall.sh

set -euo pipefail

hooks="$HOME/.claude/hooks"
files=(
  "cross-platform/check-american-english.ps1"
  "cross-platform/check-american-english.sh"
  "cross-platform/check-git-guard.ps1"
  "cross-platform/check-git-guard.sh"
  "windows-only/check-no-null-redirect.ps1"
)
for f in "${files[@]}"; do
  if [ -e "$hooks/$f" ]; then rm -f "$hooks/$f"; echo "  removed hooks/$f"; fi
done

echo
echo "Done. Manual follow-ups:"
echo "  - Remove the debussy hooks block from your ~/.claude/settings.json."
echo "  - Plugins are removed via: /plugin uninstall <name>@debussy"
