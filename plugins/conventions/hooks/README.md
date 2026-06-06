# Hooks

`PreToolUse` hooks that turn conventions Claude *should* remember into rules the
harness *enforces*. Each reads the tool-call JSON on stdin and, on a violation,
exits `2` with a stderr message Claude reads and acts on (fix, then retry).

## Layout — organized by applicability, not by language

```
hooks/
  cross-platform/    rules that apply on every OS — one runner per platform
    check-american-english.ps1   (Windows runner)
    check-american-english.sh    (Unix/WSL/macOS runner)
    check-git-guard.ps1          (Windows runner)
    check-git-guard.sh           (Unix/WSL/macOS runner)
  windows-only/      rules that only make sense on Windows
    check-no-null-redirect.ps1
```

Why this split rather than `windows/` + `unix/`:

- **`check-american-english`** is a prose rule — non-American spellings are
  wrong everywhere — so it is **cross-platform** and ships both a PowerShell
  and a Bash runner. Wire whichever matches your OS.
- **`check-no-null-redirect`** is **Windows-only on purpose.** The `nul`
  problem only exists on Windows: `>nul` / `2>nul` (especially under Git Bash,
  which doesn't always map `nul` to the null device) litters the working tree
  with stray `nul` files that are tedious to delete. On WSL and real Unices,
  `/dev/null` is the natural, idiomatic sink, so there is deliberately **no**
  `.sh` port — enforcing it there would block correct usage.

A future hook that only applies on Linux/macOS would live in a `unix-only/`
directory following the same principle.

## The hooks

### check-american-english (cross-platform)

Blocks `Write|Edit|MultiEdit|NotebookEdit` whose new content contains
non-American spellings — the `-our`, `-ise`/`-isation`, `-re`, and `-ogue`
families, plus doubled-consonant past tenses and other dialect pairs (~247
words in all). Each offending word is reported with its American replacement.

The PowerShell and Bash runners share **one** word map. The Bash version's map
is generated from the `.ps1` so the two cannot silently drift — if you add a
word, add it to the `.ps1` `$wordMap` and regenerate the `.sh` (see
"Regenerating" below), or edit both.

The matcher uses exact words (not stems) on purpose: words like `raise`,
`surprise`, `exercise`, and `license` look as if they might be British-ending
but are correct in American English, so they are intentionally absent from the
map to avoid false positives.

JSON parsing in the Bash runner uses `jq` when present (precise — scans only
content fields) and falls back to scanning the raw stdin blob when `jq` is
absent, so it degrades gracefully instead of failing open. It is portable to
bash 3.2 (the system bash on macOS) and is itself null-device-free.

> **Authoring gotcha (meta):** because this hook scans content, a document that
> legitimately *quotes* a non-American spelling as an example (like this very
> README, or a changelog entry, or a test fixture) also trips it. Workarounds:
> describe the spelling family instead of spelling the word out; assemble the
> word from fragments; or toggle the hook off via `/hooks` while authoring,
> then back on. This is the inherent cost of a content-matching hook — it
> cannot tell prose from quotation.

### check-git-guard (cross-platform)

Blocks `Bash|PowerShell` git write operations Claude must not perform:

- `git commit` / `git add` / `git stage` — the user stages and commits
  manually; Claude leaves the working tree for review.
- `git mv` / `git rm` — use plain filesystem `mv` / `rm` / rename instead, so
  moves and deletions aren't coupled to git's index.

It allows `git -C <path>` and global flags before the subcommand, and other git
verbs (`status`, `diff`, `log`, …) pass untouched. Same content-matching caveat
as the others: a command that merely *quotes* a blocked subcommand trips it.

> Note: `git push` is intentionally not blocked here (it's a separate manual
> step). Add `push` to the commit pattern if you want it guarded too.

### check-no-null-redirect (Windows-only)

Blocks `Bash|PowerShell` whose command discards output to a null device:
`/dev/null`, `>nul`, `2>nul`, `&>nul`, `nul.<ext>`. PowerShell's own `$null`
is fine — only the null *device* is blocked. Redirect to a real file path, or
drop the redirection entirely.

> Same gotcha as above: a command that merely *contains* the string `/dev/null`
> (e.g. a script you're writing that references it) also trips it. Author such
> files with the `Write` tool (this hook only matches `Bash|PowerShell`), or
> close a descriptor with `2>&-` instead of redirecting to the null device.

## Wiring — two ways

These hooks have two distribution paths (see the plugin
[README](../README.md) for the full picture):

**1. As the `conventions` plugin (recommended for sharing).** When the plugin is
enabled, [`hooks.json`](hooks.json) wires the two cross-platform hooks via
`bash` + the `.sh` runners, located with `${CLAUDE_PLUGIN_ROOT}`. No
`settings.json` edits needed. `check-no-null-redirect` is shipped but not
auto-wired (Windows-only; a plugin `hooks.json` can't branch on OS).

**2. Manual `settings.json` wiring (for the PowerShell runners / personal
always-on use).** Hooks do nothing until referenced in `settings.json` under
`hooks.PreToolUse`. Ready-to-merge snippets live in the repo-root
[`settings/`](../../../settings) directory:

- `settings.windows.example.json` — all three hooks (PowerShell runners)
- `settings.unix.example.json` — american-english + git-guard (Bash runners;
  no-null-redirect is Windows-only)

Those examples assume the hooks are installed at `~/.claude/hooks/<subdir>/...`
(the repo-root [`install.*`](../../../install.ps1) scripts copy this `hooks/`
tree there, preserving subdirectories). Merge the `hooks` block into your
existing `~/.claude/settings.json` — don't overwrite the whole file.

## Regenerating the Bash word map

The `.sh` word map is extracted from the `.ps1`. To rebuild after editing the
PowerShell map, from the repo root:

```bash
grep -oE "'[a-z]+' *= *'[a-z]+'" \
  plugins/conventions/hooks/cross-platform/check-american-english.ps1 \
  | sed -E "s/'([a-z]+)' *= *'([a-z]+)'/\1 \2/"
```

…and splice the result between the `MAP` markers in
`check-american-english.sh`.

## Testing a hook by hand

Pipe a fake tool-call payload to it and check the exit code:

```bash
# clean American text -> expect exit 0, silent
printf '%s' '{"tool_input":{"content":"optimize the color"}}' \
  | bash plugins/conventions/hooks/cross-platform/check-american-english.sh; echo "exit=$?"

# now edit the payload above to use a non-American spelling
# (e.g. the British -our / -ise forms) -> expect exit 2 plus a report
```

To toggle hooks off temporarily without editing files, run `/hooks` inside
Claude Code.
