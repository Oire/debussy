# Pre-run hook: blocks the git WRITE operations Claude must not perform.
#
# The dividing line is whether the user can undo it. A local commit comes back
# with 'git reset --soft HEAD~1' and a pushed commit comes back with a revert,
# so Claude may stage explicitly named paths, commit, and push. Everything that
# destroys work - locally or on the remote - is blocked:
#
#   push --force / -f, -d /
#   --delete, --mirror,
#   --prune, +refspec           rewriting or deleting published history. A
#                               plain push only adds to it, so it is allowed.
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
# blocked operation (a heredoc, or a commit message mentioning "reset --hard")
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
# An argument of the same subcommand: anything up to a shell chain separator or
# a line break, ending at whitespace so the flag that follows is matched as a
# whole token. Stopping at the line break keeps a flag on the next line of a
# multi-line script from being read as this command's - which is what the .sh
# runner does implicitly, since grep matches one line at a time.
$arg = '([^\r\n&|;]*[ \t])?'
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

# A plain push only adds commits to the remote, and a bad one is undone with a
# revert. These variants rewrite or delete what is already published, which no
# amount of local work brings back. '--force' is matched as a prefix on purpose,
# so '--force-with-lease' and '--force-if-includes' are caught too: the lease
# makes the race safe, not the history rewrite.
Add-Rule "push$arg(--force|--delete|--mirror|--prune|\+)" "Destructive git push blocked" @(
    "Force-pushing, deleting a remote branch, mirroring, or pruning rewrites or",
    "removes published history - the user cannot get it back.",
    "A plain 'git push' is allowed. Say what you would have force-pushed and",
    "let the user do it."
)

Add-Rule "push$arg-[A-Za-z]*[fd][A-Za-z]*$tok" "Destructive git push blocked" @(
    "'-f' force-pushes and '-d' deletes a remote branch; both rewrite or remove",
    "published history, which the user cannot get back.",
    "A plain 'git push' is allowed. Say what you would have force-pushed and",
    "let the user do it."
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
