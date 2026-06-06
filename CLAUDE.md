# CLAUDE.md

Guidance for Claude Code working inside the **debussy** repo.

## What this repo is

A Claude Code **plugin marketplace** and the source of truth for André's Claude
Code customizations. Features ship as plugins under `plugins/`, listed in
`.claude-plugin/marketplace.json`. The convention hooks also have a manual
install path (file copy into `~/.claude/hooks` + `settings.json` wiring) for
people who want the PowerShell runners or always-on use without enabling a
plugin.

## Layout

- `.claude-plugin/marketplace.json` — marketplace manifest; lists every plugin.
- `plugins/<name>/` — one plugin each. Every plugin has
  `.claude-plugin/plugin.json` and auto-discovers `agents/`, `commands/`,
  `skills/`, and `hooks/hooks.json` beneath it.
  - `planning` — brainstorm, plan-make, plan-review, plan-exec.
  - `review` — project-analyst (Nigel) + project-audit.
  - `write-manual` — the manual-writing pipeline.
  - `dotnet-tools` — the .NET style corrector.
  - `conventions` — the convention hooks (+ their `hooks/hooks.json`).
- `settings/` — `settings.{windows,unix}.example.json` for the manual hook path.
- `docs/` — design notes (`marketplace-plan.md`).
- `install.* / sync.* / uninstall.*` — helpers for the manual hook path only
  (copy `plugins/conventions/hooks` ↔ `~/.claude/hooks`). Features install via
  `/plugin`, not these scripts.

## Conventions this repo enforces (on itself)

The convention hooks are active on the author's machine, so this repo obeys its
own rules. Three will bite you while editing:

1. **American English everywhere** — the `check-american-english` hook blocks
   `Write`/`Edit` containing non-American spellings.
2. **No null-device redirects** (Windows) — `check-no-null-redirect` blocks
   `Bash`/`PowerShell` commands containing `/dev/null`, `>nul`, etc. Redirect to
   a real file, drop it, or close a descriptor with `2>&-`.
3. **No Claude-side git writes** — `check-git-guard` blocks
   `git commit`/`add`/`stage` and `git mv`/`git rm`. See the Git section.

### Authoring gotchas (important)

These hooks match on **content**, so they cannot tell prose from quotation:

- Documentation that *quotes* a non-American spelling trips the English hook.
  Describe the spelling family instead of spelling it out, assemble it from
  fragments, or toggle with `/hooks` while authoring.
- A `Bash`/`PowerShell` command that *contains* `/dev/null` (e.g. a script you're
  writing) trips the null hook. Author such files with the `Write` tool (the
  hook only matches `Bash|PowerShell`), or use `2>&-`.

## Editing rules

- **Keep the two American-English runners in sync.** The `.sh` word map is
  generated from the `.ps1`; if you change spellings, update
  `plugins/conventions/hooks/cross-platform/check-american-english.ps1` and
  regenerate the `.sh` map (procedure in that directory's `README.md`), or edit
  both identically.
- **Copy skills wholesale.** A skill is its whole `SKILL.md` + `references/` +
  `scripts/` tree, not just the `SKILL.md`.
- **Respect the windows-only vs cross-platform hook split.** A hook that only
  makes sense on Windows lives in `windows-only/` and gets no `.sh`; the plugin
  `hooks.json` only auto-wires cross-platform hooks (it can't branch on OS).
- **Don't auto-edit `~/.claude/settings.json`.** Wiring hooks manually is a
  deliberate step; the install scripts copy files but never touch settings.
- **New artifact?** Decide which plugin it belongs to (by cohesion), drop it
  under that plugin's `agents/`/`commands/`/`skills/`, and add the plugin to
  `marketplace.json` if it's new. Faithful extraction: copy verbatim and flag,
  rather than silently rewrite, any origin-project references in comments.

## Plugin authoring notes

- **Use `${CLAUDE_PLUGIN_ROOT}`** for in-plugin script/reference paths in
  SKILL.md, commands, and prompts — never `~/.claude/...`. The plugin framework
  text-substitutes it to the install location; hardcoded home paths break for
  anyone who installs the plugin. User-writable state goes under
  `${CLAUDE_PLUGIN_DATA}`; project-relative paths (e.g. `.claude/…`,
  `docs/plans/…`) stay as-is (they resolve in the user's working repo).
- **Version each plugin independently** in its `plugin.json` (semver: patch =
  fix, minor = new component, major = breaking). The marketplace has its own
  version in `metadata`.
- **Cross-references** use the plugin prefix: `/planning:plan-make`,
  `/planning:plan-exec`, etc.

### Known Claude Code limitations (manage expectations)

- Skills under `skills/*/SKILL.md` don't appear in the `/` autocomplete dropdown
  — only `commands/*.md` do. Skills are still invocable by full name
  (`/planning:plan-exec`) or natural-language intent.
- A plugin `hooks.json` can't branch on OS (hence `check-no-null-redirect` stays
  Windows-only and unwired in the conventions plugin).

## The planning trio

`plan-make` (command, writes a plan to `docs/plans/`) → `plan-review` (agent,
vets it read-only) → `plan-exec` (skill, executes it task by task). All in the
`planning` plugin, sharing the `docs/plans/<number>-<task>.md` scheme.
`brainstorm` is the design step that precedes them.

## Git

**Never commit, stage, or push** — not even as the natural last step. The user
does all git writes manually; leave changes uncommitted for review.
`check-git-guard` enforces this, but don't rely on the hook — just don't.

**Never use `git mv` or `git rm`.** Use plain `mv` / `rm` / rename (or
`Move-Item` / `Remove-Item`) so file operations aren't coupled to git's index.
