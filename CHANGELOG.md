# Changelog

All notable changes to this repo are recorded here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.5.0] - 2026-08-13

### Changed
- **conventions:** `check-git-guard` was rebuilt around *reversibility* rather
  than around "git writes" as a category. Claude may now stage explicitly named
  paths and commit locally — a commit is undone with
  `git reset --soft HEAD~1`, so the review checkpoint it used to protect is
  still available after the fact. Everything that publishes or destroys stays
  blocked, and several operations that were never guarded at all now are.

  Blocked at every level: `git push` (previously only prose in `CLAUDE.md` told
  Claude not to — the hook never checked), `commit --amend` and `rebase`
  (history rewriting), `reset --hard`, `restore`, `checkout -- <path>` /
  `checkout -f` and `clean -f` (discard work irrecoverably), bulk staging
  (`add -A` / `.` / `--all`, `commit -a`), and `git mv` / `git rm` (unchanged).

  Bulk staging is the counterweight to allowing commits: naming paths is what
  makes a delegated commit reviewable, and it keeps a sweeping add from
  quietly staging scratch output or a file with a secret in it. The
  non-destructive neighbors stay available — `reset --soft`, plain branch
  `checkout`, `checkout -b`, `clean -n`, `add -u`.

  There is deliberately no setting for this — no environment variable, no
  levels. A guard with a knob on it is a guard you have to remember the state
  of, and the point of a convention hook is that you set it up once and stop
  thinking about it. Anyone who wants Claude out of git entirely turns the hook
  off with `/hooks` or stays on conventions 0.3.x.

### Added
- **tests:** the git-guard suite grows from 11 cases to 39, covering each newly
  blocked operation and its non-destructive neighbor.

### Fixed
- **tests:** the git-guard suite now asserts the same verdicts on both
  extraction paths — the bare command (with `jq`) and the raw JSON payload
  (without it). The first draft of the token matcher passed on one and silently
  allowed `git add -A`, `git add .`, and `git clean -fd` on the other, which is
  the same failure mode `check-american-english` hit in 0.4.0.

### Notes
- `conventions` plugin bumped to 0.4.0 (hook behavior changed); marketplace
  bumped to 0.5.0. Other plugin versions unchanged.
- Existing installs pick this up on `/plugin update conventions@debussy` (or
  auto-update). Anyone who wants the old behavior stays on 0.3.x.

## [0.4.0] - 2026-08-01

### Fixed
- **conventions:** `check-american-english` (Bash runner) only applied its
  path-based skips when `jq` happened to be installed. Without `jq` the hook
  could not read `file_path` at all, fell back to scanning the raw payload, and
  every skip added in 0.2.0 silently stopped applying — a `.po` file was still
  blocked. The failure was invisible and untested, so it went unnoticed since
  0.2.0. The runner now lifts the path out of the raw JSON when `jq` is absent
  (Git Bash on Windows, typically) and normalizes Windows backslash paths
  before matching.

### Added
- **conventions:** `check-american-english` now also skips Apple localization
  catalogs (`.strings`, `.stringsdict`, `.xcstrings`) and files sitting in an
  unambiguous locale directory — `fr.lproj`, `fr-FR`, `pt_BR`, `zh-Hant`,
  `es-419`, Android's `values-fr`/`values-pt-rBR`, and a bare code like `fr`
  directly inside `locales/`, `_locales/`, `lang(s)/`, `i18n/`, `intl/` or
  `translations/`. English locales stay checked.

  A bare two-letter directory is deliberately not a skip signal by itself: many
  ISO 639-1 codes double as ordinary directory names (`it` is Maven's
  integration-test directory; `sh`, `so`, `ts`, `cs`, `pl`, `ml`, `gl`, `hr`,
  `el`, `id`, `is`, `no` are all codes too). A wrong skip fails silently and
  permanently; a wrong block is loud and self-correcting, so skipping carries
  the higher bar.

  Apple's catalogs are skipped for every locale including English, because their
  keys are identifiers the author cannot rename and match the word map whatever
  language the values use — the trade-off `.po` already makes with its English
  msgids.
- **tests:** 17 cases covering the path skips, which previously had none. They
  assert both directions (skipped vs still checked) and pass with and without
  `jq`, so a regression in path extraction fails the suite instead of quietly
  disabling the feature.

### Notes
- `conventions` plugin bumped to 0.3.0 (hook behavior changed); marketplace
  bumped to 0.4.0. Other plugin versions unchanged.

## [0.3.0] - 2026-07-12

### Changed
- **Positioning / docs:** reframed the marketplace as a public, general-purpose
  set of plugins rather than one person's machine setup. The root `README` and
  `CLAUDE.md` no longer describe debussy as customizations for a specific
  machine, and the **conventions** plugin is now explicitly labeled *opinionated
  Oire conventions* (organization policy, opt-in) to set it apart from the
  everyone-friendly plugins (planning, review, write-manual, dotnet-tools).
- **conventions hooks README:** documented a third wiring path — enable the
  plugin for the cross-platform hooks and add only the Windows-only
  `check-no-null-redirect` via a single `settings.json` entry that points at the
  plugin's own shipped script, so it tracks marketplace auto-updates instead of
  drifting from an `install.ps1` copy. Added a "don't double-wire" caution (the
  plugin's `.sh` runners plus the PowerShell runners of the same hook fire
  twice) and noted the plugin-storage-path trade-off. Verified the PowerShell
  no-null-redirect wiring end to end on Windows 11 with Git Bash.

### Notes
- Marketplace version bumped to 0.3.0 (`marketplace.json` metadata). Individual
  plugin versions are unchanged — no plugin behavior changed, only docs and
  positioning.

## [0.2.0] - 2026-07-12

### Changed
- **conventions:** `check-american-english` (Bash and PowerShell) now skips
  files that never hold the author's English prose — `lang(s)/*.php`,
  `*.po`/`*.pot`/`*.xlf`/`*.xliff`, and any HTML document whose root
  `<html lang="…">` is not `en*`. Translated content (message catalogs and
  localized pages) no longer trips the hook as a false positive. English source
  files, including HTML with `lang="en"`, are still checked.

## [0.1.0] - 2026-06-06

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
