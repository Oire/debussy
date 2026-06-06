#!/usr/bin/env bash
# Pre-run hook: blocks git WRITE operations Claude must not perform. Two rules,
# both user conventions turned into harness enforcement:
#
#   1. Never commit or stage. The user stages and commits manually; Claude
#      leaves the working tree for review. Blocks: git commit / git add /
#      git stage.
#   2. Never use 'git mv' or 'git rm'. Use plain filesystem mv / rm / rename
#      so moves and deletions are not coupled to git's index.
#
# Unix (Linux/macOS/WSL) counterpart of check-git-guard.ps1. On a match it
# exits 2 with a stderr message Claude reads and acts on. Wired in settings.json
# under hooks.PreToolUse with matcher "Bash|PowerShell". Portable to bash 3.2;
# null-device-free (closes fd 2 with 2>&-).
#
# Caveat: matches on command text, so a command that merely *quotes* a blocked
# subcommand also trips it. Author such content with the Write tool.

set -u

raw=$(cat)
[ -z "${raw//[$' \t\n\r']/}" ] && exit 0

jqbin=$(command -v jq || true)
if [ -n "$jqbin" ]; then
  cmd=$("$jqbin" -r '.tool_input.command // empty' <<<"$raw" 2>&-)
  [ -z "$cmd" ] && cmd="$raw"
else
  cmd="$raw"
fi
[ -z "$cmd" ] && exit 0

# ERE has no \b; emulate a word boundary with a non-alnum prefix/suffix. Allow
# 'git -C <path>' and global flags between 'git' and the subcommand.
pre='(^|[^[:alnum:]_])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(-[^[:space:]]+[[:space:]]+)*'
suf='([^[:alnum:]_]|$)'

if printf '%s' "$cmd" | grep -qiE "${pre}(commit|add|stage)${suf}" 2>&-; then
  {
    echo "Git commit/stage blocked. You do not commit or stage in this repo:"
    echo
    echo "  $cmd"
    echo
    echo "Leave all changes uncommitted in the working tree for the user to review."
    echo "The user stages, commits, and pushes manually."
  } >&2
  exit 2
fi

if printf '%s' "$cmd" | grep -qiE "${pre}(mv|rm)${suf}" 2>&-; then
  {
    echo "git mv / git rm blocked. Use plain filesystem operations instead:"
    echo
    echo "  $cmd"
    echo
    echo "Use mv / rm / rename so file moves and deletions are not coupled to"
    echo "git's index. The user manages git staging."
  } >&2
  exit 2
fi

exit 0
