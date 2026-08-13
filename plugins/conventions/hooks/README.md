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

**What it skips.** Files that never hold the author's English prose:

- `lang/` and `langs/` PHP message files.
- Translation-only formats: `.po`, `.pot`, `.xlf`, `.xliff`, and Apple's
  `.strings`, `.stringsdict`, `.xcstrings`.
- Any HTML document whose root `<html lang="…">` is not `en*`.
- Files inside an unambiguous **locale directory** — `fr.lproj`, `fr-FR`,
  `pt_BR`, `zh-Hant`, `es-419`, Android's `values-fr` / `values-pt-rBR`, or a
  bare code like `fr` when it sits directly inside `locales/`, `_locales/`,
  `lang(s)/`, `i18n/`, `intl/` or `translations/`. English locales (`en`,
  `en-GB`, `en.lproj`, `Base.lproj`, `values-en`) stay checked.

A bare two-letter directory is deliberately **not** a skip signal on its own:
plenty of ISO 639-1 codes double as ordinary directory names. `it` is Maven's
integration-test directory (`src/it/`), and `sh`, `so`, `ts`, `cs`, `pl`, `ml`,
`gl`, `hr`, `el`, `id`, `is` and `no` are all real language codes as well as
everyday folder names. The two mistakes are not symmetrical — a wrong skip fails
silently and permanently, while a wrong block is loud and self-correcting — so
the bar for adding a skip is higher than the bar for tolerating a block.

Apple's catalogs are skipped for **every** locale, English included, because
their *keys* are identifiers the author cannot rename: a key naming an operation
that was stopped matches the word map no matter which language the values are
written in. `.po` already makes the same trade-off, since it carries English
msgids.

The target path is read with `jq` when present and lifted from the raw JSON
otherwise, so every skip above also works on machines without `jq` (Git Bash on
Windows, typically). Windows backslash paths are normalized before matching.

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

Blocks the `Bash|PowerShell` git write operations Claude must not perform.
Claude **may** stage explicitly named paths and commit locally. Everything that
publishes work or destroys it is blocked:

| Blocked | Why |
| --- | --- |
| `git push` | Publishing is the user's call. |
| `git commit --amend`, `git rebase` | History rewriting. |
| `git reset --hard`, `git restore`, `git checkout -- <path>` / `-f`, `git clean -f` | Discard work with nothing to recover it from. |
| `git add -A` / `.` / `--all`, `git commit -a` | Bulk staging — name the paths instead, so nothing is staged that Claude hasn't looked at. |
| `git mv`, `git rm` | Use plain `mv` / `rm` / rename, so moves and deletions aren't coupled to git's index. |

The line between the two lists is *reversibility*. A local commit is undone with
`git reset --soft HEAD~1`; everything in the table either publishes work or
destroys it. The bulk-staging block is the other half of that bargain — the
reason a commit is safe to let Claude make is that Claude named every path going
into it.

The non-destructive neighbors of the blocked commands stay available:
`git reset --soft`, `git checkout <branch>`, `git checkout -b`, `git clean -n`,
`git add -u`, and every read-only verb (`status`, `diff`, `log`, …).

It allows `git -C <path>` and global flags before the subcommand. Flags are
matched as whole tokens, so `git add .` is blocked while `git add .gitignore`
and `git add ./src/foo.ts` are not. Same content-matching caveat as the others:
a command that merely *quotes* a blocked operation trips it — including a commit
message that happens to mention pushing.

There is deliberately nothing to configure. If you want Claude out of git
entirely, turn the hook off with `/hooks`, or stay on conventions 0.3.x, where
`add`/`stage`/`commit` were blocked outright.

### check-no-null-redirect (Windows-only)

Blocks `Bash|PowerShell` whose command discards output to a null device:
`/dev/null`, `>nul`, `2>nul`, `&>nul`, `nul.<ext>`. PowerShell's own `$null`
is fine — only the null *device* is blocked. Redirect to a real file path, or
drop the redirection entirely.

> Same gotcha as above: a command that merely *contains* the string `/dev/null`
> (e.g. a script you're writing that references it) also trips it. Author such
> files with the `Write` tool (this hook only matches `Bash|PowerShell`), or
> close a descriptor with `2>&-` instead of redirecting to the null device.

## Wiring

These hooks reach your machine through a few paths (see the plugin
[README](../README.md) for the overview); pick per hook.

### 1. As the `conventions` plugin (recommended for the cross-platform hooks)

When the plugin is enabled, [`hooks.json`](hooks.json) wires the two
cross-platform hooks via `bash` + the `.sh` runners, located with
`${CLAUDE_PLUGIN_ROOT}`. No `settings.json` edits, and marketplace auto-update
keeps them current. `check-no-null-redirect` is shipped but not auto-wired
(Windows-only; a plugin `hooks.json` can't branch on OS).

### 2. Manual `settings.json` wiring (the PowerShell runners)

For the native PowerShell runners (more precise JSON parsing, no `bash`
dependency), or always-on use without enabling the plugin. Hooks do nothing
until referenced in `settings.json` under `hooks.PreToolUse`. Ready-to-merge
snippets live in the repo-root [`settings/`](../../../settings) directory:

- `settings.windows.example.json` — all three hooks (PowerShell runners)
- `settings.unix.example.json` — american-english + git-guard (Bash runners;
  no-null-redirect is Windows-only)

Those examples assume the hooks are installed at `~/.claude/hooks/<subdir>/...`
(the repo-root [`install.*`](../../../install.ps1) scripts copy this `hooks/`
tree there, preserving subdirectories). Merge the `hooks` block into your
existing `~/.claude/settings.json` — don't overwrite the whole file.

> **Don't double-wire.** If the `conventions` plugin is enabled, it already runs
> `check-american-english` and `check-git-guard` (the `.sh` runners). Wiring the
> PowerShell versions of those two *on top* makes each fire twice on every
> matching call. Use path 2 for the cross-platform hooks only when the plugin is
> **not** enabled.

### 3. Plugin + only the Windows-only hook (the common Windows setup)

If you enable the plugin for the cross-platform hooks and just want to add
`check-no-null-redirect` on Windows, you don't need to copy anything or run
`install.ps1`. Wire one `settings.json` entry that points straight at the script
the plugin already ships, so it tracks marketplace auto-updates:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"${USERPROFILE}/.claude/plugins/marketplaces/Debussy/plugins/conventions/hooks/windows-only/check-no-null-redirect.ps1\"",
            "shell": "bash",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

The `shell: "bash"` lets Git Bash expand `${USERPROFILE}` before it hands the
resolved path to `powershell.exe`. The `marketplaces/Debussy/` segment is the
marketplace's `name` from `marketplace.json` — adjust if yours differs.

Trade-off: this reaches into Claude Code's plugin storage, which is not a
formally documented location. It works today and auto-updates with the
marketplace; if a future Claude Code reorganizes plugin storage you'd fix the
path. The copy-based path (2, via `install.ps1`) is insulated from that but does
not auto-update — you re-run `install.ps1` after each hook change. Verified on
Windows 11 with Git Bash: a violating command exits `2` and is blocked; a clean
command and PowerShell's own `$null` pass.

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
