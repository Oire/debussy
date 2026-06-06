# conventions (plugin)

Oire coding conventions, enforced as `PreToolUse` hooks. These are
**organization policy**, not universal truths, so they live behind an explicit
opt-in: enable this plugin only if you want them.

## What it enforces

- **`check-american-english`** (cross-platform) — blocks writes containing
  non-American spellings, naming each word and its American replacement.
- **`check-git-guard`** (cross-platform) — blocks `git commit`/`add`/`stage`
  (commit manually) and `git mv`/`git rm` (use plain `mv`/`rm`/rename).
- **`check-no-null-redirect`** (Windows-only) — blocks null-device redirects,
  which on Windows leave stray `nul` files. **Not auto-wired** (see below).

Full per-hook details, the word-map regeneration procedure, and the
content-matching gotchas are in [`hooks/README.md`](hooks/README.md).

## Install

```
/plugin marketplace add Oire/debussy
/plugin install conventions@debussy
```

When enabled, `hooks/hooks.json` wires the two **cross-platform** hooks via
`bash` (using the `.sh` runners, which work on Linux, macOS, WSL, and Windows
Git Bash; they fall back to a raw-content scan when `jq` is absent).

## Why no-null-redirect isn't auto-wired

A plugin's `hooks.json` is static — it can't branch on the operating system.
`check-no-null-redirect` is correct only on Windows (on Unix, `/dev/null` is
idiomatic and blocking it would be wrong). Auto-wiring it would fire it on every
OS, so the plugin ships the script but leaves it unwired. Windows users who want
it should wire it manually in their own `settings.json` — see the repo-root
`settings/` examples.

## Prefer the PowerShell runners (Windows, no Git Bash)?

The plugin uses the `bash`/`.sh` path for portability. If you'd rather use the
native PowerShell runners (more precise JSON parsing, no `bash` dependency),
skip the plugin for hooks and wire the `.ps1` files manually via `settings.json`
— the repo's `install.*` scripts and `settings/` examples set that up.
