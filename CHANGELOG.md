# Changelog

All notable changes to this repo are recorded here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.0] - 2026-07-12

### Changed
- **conventions:** `check-american-english` (Bash and PowerShell) now skips
  files that never hold the author's English prose — `lang(s)/*.php`,
  `*.po`/`*.pot`/`*.xlf`/`*.xliff`, and any HTML document whose root
  `<html lang="…">` is not `en*`. Translated content (message catalogs and
  localized pages) no longer trips the hook as a false positive. English source
  files, including HTML with `lang="en"`, are still checked.

## [0.1.0] - 2026-06-10

### Added
- Plugin marketplace (`.claude-plugin/marketplace.json`) exposing five plugins:
  - **planning** — brainstorm, plan-make, plan-review, plan-exec.
  - **review** — project-analyst (Nigel) + project-audit.
  - **write-manual** — accessible user-manual pipeline.
  - **dotnet-tools** — Oire .NET style corrector.
  - **conventions** — opt-in convention hooks with a `hooks/hooks.json`.
- Hooks (in the conventions plugin), organized by applicability:
  - `cross-platform/check-american-english` — PowerShell + Bash runners sharing
    one word map (the Bash map is generated from the PowerShell source).
  - `cross-platform/check-git-guard` — blocks `git commit`/`add`/`stage` and
    `git mv`/`git rm` (PowerShell + Bash).
  - `windows-only/check-no-null-redirect` — Windows-only; not ported to Unix.
- Manual hook path: `settings/` snippets (Windows + Unix) and
  `install.* / sync.* / uninstall.*` helpers that copy the convention hooks
  into/out of `~/.claude/hooks`.
- `CLAUDE.md`, human-facing `README.md`, `.gitignore`, and
  `docs/marketplace-plan.md` (the packaging rationale).
- LICENSE attribution filled in (Apache-2.0, Copyright 2026 André Polykanine).
- Attribution to [cc-thingz by Umputun](https://github.com/umputun/cc-thingz):
  the `planning` plugin is adapted from his MIT-licensed work. Added `NOTICE`
  (retaining his MIT notice; Apache-2.0 and MIT are compatible), README credits,
  and a per-plugin attribution note.
- CI workflow (`.github/workflows/ci.yml`): YAML-frontmatter validation, JSON
  manifest validation, ShellCheck, and the hook test suite.
- `tests/` — bash tests for the cross-platform convention hooks
  (`test-american-english.sh`, `test-git-guard.sh`).
- `plugin.json` polish: `homepage`, `repository`, `license` on every plugin.

### Fixed
- **Plugins now work when installed.** Skills referenced scripts at
  `~/.claude/skills/...` (the old file-copy path), which broke under plugin
  install; switched to `${CLAUDE_PLUGIN_ROOT}` across planning/review/
  write-manual, and moved user-level custom rules to `${CLAUDE_PLUGIN_DATA}`
  (plugin-aware `resolve-rules.sh`, adapted from cc-thingz).
- `plan-review` agent: quoted its YAML frontmatter (was invalid strict YAML) and
  corrected a stale `/action:plan` reference to `/planning:plan-make`.

### Notes
- This repo enforces its own conventions on itself (American English; no
  null-device redirects on Windows; no Claude-side git commits/staging or
  `git mv`/`git rm`), so authoring sometimes works around the very hooks it
  ships — see `plugins/conventions/hooks/README.md`.
- `check-no-null-redirect` is intentionally Windows-only and is not auto-wired
  by the conventions plugin (a plugin `hooks.json` can't branch on OS).
