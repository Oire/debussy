#!/usr/bin/env bash
# Reverse of install.sh: pulls convention hooks edited directly in
# ~/.claude/hooks back INTO this repo (plugins/conventions/hooks), so in-place
# tweaks aren't lost. Review with `git diff` before committing.
#
# Only the manually-installed hooks are synced. Plugin contents are managed by
# the marketplace, not file copy, and are not synced here.
#
# Usage (from the repo root):   bash sync.sh

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$HOME/.claude/hooks"
dest="$repo/plugins/conventions/hooks"

if [ ! -d "$src" ]; then echo "Nothing to sync: $src does not exist."; exit 0; fi

echo "Syncing convention hooks from $src into $dest"
echo "(Overwrites repo copies. Review with git diff before committing.)"
for sub in cross-platform windows-only; do
  [ -d "$src/$sub" ] || continue
  mkdir -p "$dest/$sub"
  cp -R "$src/$sub/." "$dest/$sub/"
  echo "  pulled hooks/$sub/"
done

echo
echo "Done. Now: git status / git diff, then commit manually."
echo "If you changed the American-English word map in the .ps1, regenerate the"
echo ".sh map (see plugins/conventions/hooks/README.md)."
