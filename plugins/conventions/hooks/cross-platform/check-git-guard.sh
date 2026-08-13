#!/usr/bin/env bash
# Pre-run hook: blocks the git WRITE operations Claude must not perform.
#
# The dividing line is whether the user can undo it. A local commit comes back
# with 'git reset --soft HEAD~1', so Claude may stage explicitly named paths and
# commit. Everything that publishes work or destroys it is blocked:
#
#   push                        publishing is the user's call.
#   commit --amend, rebase      history rewriting.
#   reset --hard, restore,
#   checkout -- / -f, clean -f  discard work with nothing to recover it from.
#   add -A / . / --all,
#   commit -a                   bulk staging - name the paths instead, so
#                               nothing is staged that Claude has not seen.
#   mv, rm                      use plain mv / rm / rename, so moves and
#                               deletions are not coupled to git's index.
#
# The bulk-staging block is the counterweight to allowing commits at all: what
# makes a delegated commit reviewable is that every path in it was named.
#
# Unix (Linux/macOS/WSL) counterpart of check-git-guard.ps1. On a match it
# exits 2 with a stderr message Claude reads and acts on. Wired in settings.json
# under hooks.PreToolUse with matcher "Bash|PowerShell". Portable to bash 3.2;
# null-device-free (closes fd 2 with 2>&-). To turn the whole hook off for a
# session, use /hooks inside Claude Code.
#
# Caveat: matches on command text, so a command that merely *quotes* a blocked
# operation also trips it. Author such content with the Write tool.

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
# An argument of the same subcommand: anything up to a shell chain separator,
# ending at whitespace so the flag that follows is matched as a whole token.
arg='([^&|;]*[[:space:]])?'
# A blocked flag must end as a whole token, never mid-token: the next character
# has to be one that cannot continue a flag or path. Whitespace qualifies, and
# so does the closing quote seen on the no-jq path, where the command is still
# wrapped in its JSON payload. This is what keeps 'git add .' apart from
# 'git add .gitignore'.
tok='([^[:alnum:]_./:=-]|$)'

matches() { printf '%s' "$cmd" | grep -qiE "$1" 2>&-; }

block() {
  title="$1"
  shift
  {
    echo "$title"
    echo
    echo "  $cmd"
    echo
    for line in "$@"; do echo "$line"; done
  } >&2
  exit 2
}

if matches "${pre}push${suf}"; then
  block "git push blocked" \
    "Pushing publishes work and is the user's call, always." \
    "Commit locally instead, then tell the user what is ready to push."
fi

if matches "${pre}(mv|rm)${suf}"; then
  block "git mv / git rm blocked" \
    "Use mv / rm / rename so file moves and deletions are not coupled to" \
    "git's index."
fi

if matches "${pre}commit${arg}--amend${tok}"; then
  block "git commit --amend blocked" \
    "Amending rewrites history. Make a new commit instead, or tell the user" \
    "what the previous commit got wrong and let them amend it."
fi

if matches "${pre}rebase${suf}"; then
  block "git rebase blocked" \
    "Rebasing rewrites history. Leave the branch as it is and tell the user" \
    "what you would have rebased onto."
fi

if matches "${pre}reset${arg}--hard${tok}"; then
  block "git reset --hard blocked" \
    "This throws away uncommitted work with nothing to recover it from." \
    "To undo a commit you just made, use 'git reset --soft HEAD~1', which" \
    "keeps the changes in the working tree."
fi

if matches "${pre}restore${suf}"; then
  block "git restore blocked" \
    "This discards changes in the working tree with no way back." \
    "If a file should be reverted, say so and let the user do it."
fi

if matches "${pre}checkout${arg}(--|-f|--force)${tok}"; then
  block "Destructive git checkout blocked" \
    "'git checkout -- <path>' and 'checkout -f' discard working-tree changes" \
    "with no way back. Switching branches without them is fine."
fi

if matches "${pre}clean${arg}(-[[:alpha:]]*f[[:alpha:]]*|--force)${tok}"; then
  block "git clean --force blocked" \
    "This deletes untracked files, which git has no copy of." \
    "Run 'git clean -n' to report what it would delete and let the user decide."
fi

if matches "${pre}add${arg}(-[[:alpha:]]*A[[:alpha:]]*|--all|\.|:/|\*)${tok}"; then
  block "Bulk 'git add' blocked" \
    "Stage the paths you changed by name: 'git add path/one path/two'." \
    "A sweeping add stages files you have not looked at - scratch output," \
    "build artifacts, or something with a secret in it."
fi

if matches "${pre}commit${arg}(-[[:alpha:]]*a[[:alpha:]]*|--all)${tok}"; then
  block "'git commit -a' blocked" \
    "'-a' stages every tracked change, including ones you did not review." \
    "Stage the paths you changed by name, then commit without '-a'."
fi

exit 0
