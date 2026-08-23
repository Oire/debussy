# Pre-run hook: blocks Bash / PowerShell tool calls whose command discards
# output to a null device. The user's global convention is to redirect to a
# real file path or drop the redirection entirely - never to a null sink.
#
# This converts the rule from "Claude has to remember" into "the harness
# enforces it." Mirrors check-american-english.ps1: it reads the tool-call JSON
# from stdin and, on a match, exits with code 2 and writes a stderr message that
# Claude sees and is expected to act on (rewrite the command, then retry).
#
# Installed user-globally - fires in every project on this machine.
# To audit / edit:
#   - This file: ~/.claude/hooks/windows-only/check-no-null-redirect.ps1
#   - Wired in ~/.claude/settings.json (user scope) under hooks.PreToolUse
#     with matcher "Bash|PowerShell".
# To disable temporarily: run /hooks in Claude Code, or remove the entry from
# ~/.claude/settings.json.
#
# Note: PowerShell instead of bash because Git Bash on this machine has no jq.
# PowerShell ships native JSON parsing and is fine for a Windows-only project.

$ErrorActionPreference = 'Stop'

# Read the tool-call JSON from stdin.
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
} catch {
    # Malformed JSON shouldn't block the call; let it through.
    exit 0
}

$cmd = [string]$payload.tool_input.command
if ([string]::IsNullOrEmpty($cmd)) {
    exit 0
}

# What we block:
#   /dev/null                  -- the Unix null device, in any position
#   > nul / 2>nul / &>nul      -- the Windows NUL device as a redirect target
#   >nul.txt                   -- NUL device even with an extension (Windows
#                                 treats "nul.<anything>" as the device)
# The (?![A-Za-z]) lookahead keeps a genuine file like "null.log" from matching,
# and PowerShell's own "$null" (the documented, allowed idiom) never matches
# because it has no ">nul" / "/dev/null" form.
$patterns = @(
    '/dev/null',
    '>\s*nul(?![A-Za-z])'
)
$regex = [Regex]::new(($patterns -join '|'), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if (-not $regex.IsMatch($cmd)) {
    exit 0
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("No-null-redirects convention violated. This command discards output to a null device:")
$lines.Add("")
$lines.Add("  $cmd")
$lines.Add("")
$lines.Add("Convention (Windows: no null-device redirects -- they leave stray 'nul' files):")
$lines.Add("never use /dev/null, >nul, or nul. Redirect to a real file path, or drop the redirection entirely.")
$lines.Add("(PowerShell's own `$null is fine - only the null *device* is blocked.)")

[Console]::Error.WriteLine([string]::Join("`n", $lines))
exit 2
