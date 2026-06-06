#!/usr/bin/env bash
# Installs the convention HOOKS into ~/.claude on Linux/macOS/WSL for the manual
# settings.json wiring path. Most users should instead enable the 'conventions'
# plugin (which wires these via hooks.json automatically); use this script only
# if you specifically want to wire them yourself through settings.json.
#
# Everything else in debussy ships as plugins installed via the marketplace:
#   /plugin marketplace add Oire/debussy
#   /plugin install planning@debussy   (and review, write-manual, dotnet-tools)
#
# Copies plugins/conventions/hooks/* into ~/.claude/hooks/, preserving the
# cross-platform/ and windows-only/ subdirectories. Does NOT touch settings.json.
#
# Usage (from the repo root):   bash install.sh

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$repo/plugins/conventions/hooks"
dest="$HOME/.claude/hooks"

echo "Installing convention hooks into $dest"
mkdir -p "$dest"
# Copy the runners and subdirs, but not the plugin's hooks.json or README.
cp -R "$src/cross-platform" "$dest/"
cp -R "$src/windows-only" "$dest/"
chmod +x "$dest/cross-platform/check-american-english.sh" "$dest/cross-platform/check-git-guard.sh" 2>&- || true

cat <<'EOF'

Done. Next steps:
  1. Merge the hooks block from settings/settings.unix.example.json into
     ~/.claude/settings.json (under hooks.PreToolUse).
     (check-no-null-redirect is Windows-only and is intentionally not wired
     on Unix.)
  2. Restart Claude Code (or run /hooks) so the hooks load.

Features (planning, review, write-manual, dotnet-tools) install via the
marketplace: /plugin marketplace add Oire/debussy
EOF
