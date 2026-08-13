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
# On a match it exits 2 with a stderr message Claude reads and acts on.
# Cross-platform rule (git is everywhere); the Bash counterpart is
# check-git-guard.sh. Wired in settings.json under hooks.PreToolUse with
# matcher "Bash|PowerShell". To turn the whole hook off for a session, use
# /hooks inside Claude Code.
#
# Caveat: this matches on command text, so a command that merely *quotes* a
# blocked operation (a heredoc, or a commit message mentioning "git push")
# also trips it. Author such content with the Write tool, which this hook does
# not match.

$ErrorActionPreference = 'Stop'

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrEmpty($cmd)) { exit 0 }

$opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
# Allow 'git -C <path>' and any global flags before the subcommand.
$flags = '(-C\s+\S+\s+)?(--?\S+\s+)*'
# An argument of the same subcommand: anything up to a shell chain separator,
# ending at whitespace so the flag that follows is matched as a whole token.
$arg = '([^&|;]*\s)?'
# A blocked flag must end as a whole token, never mid-token: the next character
# has to be one that cannot continue a flag or path. Whitespace qualifies, and
# so does a closing quote. This is what keeps 'git add .' apart from
# 'git add .gitignore'.
$tok = '([^A-Za-z0-9_./:=-]|$)'

$rules = @()
function Add-Rule([string]$pattern, [string]$title, [string[]]$advice) {
    $script:rules += [pscustomobject]@{
        Regex  = [Regex]::new("\bgit\s+$flags$pattern", $opts)
        Title  = $title
        Advice = $advice
    }
}

Add-Rule "push\b" "git push blocked" @(
    "Pushing publishes work and is the user's call, always.",
    "Commit locally instead, then tell the user what is ready to push."
)

Add-Rule "(mv|rm)\b" "git mv / git rm blocked" @(
    "Use mv / rm / rename (or Move-Item / Remove-Item) so file moves and",
    "deletions are not coupled to git's index."
)

Add-Rule "commit$arg--amend$tok" "git commit --amend blocked" @(
    "Amending rewrites history. Make a new commit instead, or tell the user",
    "what the previous commit got wrong and let them amend it."
)

Add-Rule "rebase\b" "git rebase blocked" @(
    "Rebasing rewrites history. Leave the branch as it is and tell the user",
    "what you would have rebased onto."
)

Add-Rule "reset$arg--hard$tok" "git reset --hard blocked" @(
    "This throws away uncommitted work with nothing to recover it from.",
    "To undo a commit you just made, use 'git reset --soft HEAD~1', which",
    "keeps the changes in the working tree."
)

Add-Rule "restore\b" "git restore blocked" @(
    "This discards changes in the working tree with no way back.",
    "If a file should be reverted, say so and let the user do it."
)

Add-Rule "checkout$arg(--|-f|--force)$tok" "Destructive git checkout blocked" @(
    "'git checkout -- <path>' and 'checkout -f' discard working-tree changes",
    "with no way back. Switching branches without them is fine."
)

Add-Rule "clean$arg(-[a-z]*f[a-z]*|--force)$tok" "git clean --force blocked" @(
    "This deletes untracked files, which git has no copy of.",
    "Run 'git clean -n' to report what it would delete and let the user decide."
)

Add-Rule "add$arg(-[a-z]*A[a-z]*|--all|\.|:/|\*)$tok" "Bulk 'git add' blocked" @(
    "Stage the paths you changed by name: 'git add path/one path/two'.",
    "A sweeping add stages files you have not looked at - scratch output,",
    "build artifacts, or something with a secret in it."
)

Add-Rule "commit$arg(-[a-z]*a[a-z]*|--all)$tok" "'git commit -a' blocked" @(
    "'-a' stages every tracked change, including ones you did not review.",
    "Stage the paths you changed by name, then commit without '-a'."
)

foreach ($rule in $rules) {
    if ($rule.Regex.IsMatch($cmd)) {
        $msg = @($rule.Title, "", "  $cmd", "") + $rule.Advice
        [Console]::Error.WriteLine([string]::Join("`n", $msg))
        exit 2
    }
}

exit 0
