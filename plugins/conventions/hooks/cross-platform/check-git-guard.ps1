# Pre-run hook: blocks git WRITE operations Claude must not perform. Two rules,
# both user conventions turned into harness enforcement:
#
#   1. Never commit or stage. The user stages and commits manually; Claude
#      leaves the working tree for review. Blocks: git commit / git add /
#      git stage.
#   2. Never use 'git mv' or 'git rm'. Use plain filesystem mv / rm / rename
#      so moves and deletions are not coupled to git's index.
#
# On a match it exits 2 with a stderr message Claude reads and acts on.
# Cross-platform rule (git is everywhere); the Bash counterpart is
# check-git-guard.sh. Wired in settings.json under hooks.PreToolUse with
# matcher "Bash|PowerShell".
#
# Caveat: this matches on command text, so a command that merely *quotes*
# "git commit" (e.g. in a heredoc or echo) also trips it. Author such content
# with the Write tool, which this hook does not match.

$ErrorActionPreference = 'Stop'

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrEmpty($cmd)) { exit 0 }

# Allow 'git -C <path>' and any global flags before the subcommand.
$flags = '(-C\s+\S+\s+)?(--?\S+\s+)*'
$opts  = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$reCommit = [Regex]::new("\bgit\s+$flags(commit|add|stage)\b", $opts)
$reMove   = [Regex]::new("\bgit\s+$flags(mv|rm)\b", $opts)

if ($reCommit.IsMatch($cmd)) {
    $msg = @(
        "Git commit/stage blocked. You do not commit or stage in this repo:",
        "",
        "  $cmd",
        "",
        "Leave all changes uncommitted in the working tree for the user to review.",
        "The user stages, commits, and pushes manually."
    )
    [Console]::Error.WriteLine([string]::Join("`n", $msg))
    exit 2
}

if ($reMove.IsMatch($cmd)) {
    $msg = @(
        "git mv / git rm blocked. Use plain filesystem operations instead:",
        "",
        "  $cmd",
        "",
        "Use mv / rm / rename (or Move-Item / Remove-Item) so file moves and",
        "deletions are not coupled to git's index. The user manages git staging."
    )
    [Console]::Error.WriteLine([string]::Join("`n", $msg))
    exit 2
}

exit 0
