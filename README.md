# Debussy

[![CI](https://github.com/Oire/debussy/actions/workflows/ci.yml/badge.svg)](https://github.com/Oire/debussy/actions/workflows/ci.yml)

Claude. Claude Debussy. 🎹

A Claude Code **plugin marketplace** from [Oire](https://oire.org): a small set
of plugins for planning, review, documentation, and .NET work — plus an opt-in
pack of opinionated Oire coding conventions. Packaged so both humans and Claude
can navigate it, and so you can install just the pieces you want.

## What's inside

```
debussy/
  .claude-plugin/marketplace.json   the marketplace manifest (lists the plugins)
  plugins/
    planning/        brainstorm + plan-make + plan-review + plan-exec
    review/          project-analyst (Nigel) + project-audit
    write-manual/    accessible user-manual pipeline
    dotnet-tools/    Oire .NET style corrector
    conventions/     opt-in convention hooks (American English, git-guard)
  settings/          settings.json snippets for manual hook wiring
  docs/              design notes (marketplace roadmap)
  install.* sync.* uninstall.*   helpers for the manual hook path
```

## The plugins

| Plugin | What it gives you | Install |
| --- | --- | --- |
| [planning](#planning) | brainstorm, plan-make, plan-review, plan-exec | `/plugin install planning@debussy` |
| [review](#review) | project-analyst (Nigel), project-audit | `/plugin install review@debussy` |
| [write-manual](#write-manual) | accessible user-manual pipeline | `/plugin install write-manual@debussy` |
| [dotnet-tools](#dotnet-tools) | .NET style corrector | `/plugin install dotnet-tools@debussy` |
| [conventions](#conventions-opt-in) | opt-in convention hooks | `/plugin install conventions@debussy` |

Add the marketplace once, then install whichever you want:

```
/plugin marketplace add Oire/debussy
/plugin install planning@debussy
```

To try a plugin from a local checkout without publishing, point Claude Code at
the plugin directory: `claude --plugin-dir plugins/planning` (and `/reload-plugins`
inside a session picks up edits). Or add the whole local repo as a marketplace:
`/plugin marketplace add <path-to-debussy>`.

### planning

The idea-to-execution pipeline; the four components chain via the
`docs/plans/<number>-<task>.md` convention.

| Component | Trigger | Description |
| --- | --- | --- |
| `brainstorm` (skill) | `/planning:brainstorm`, or "brainstorm", "help me design" | One-question-at-a-time conversation that turns a rough idea into a validated design |
| `plan-make` (command) | `/planning:plan-make` | Writes a structured implementation plan to `docs/plans/` |
| `plan-review` (agent) | Task tool, or "review my plan" | Read-only review of a plan for completeness, correctness, and over-engineering before any code |
| `plan-exec` (skill) | `/planning:plan-exec`, or "execute plan" | Executes the plan task by task in isolated subagents, leaving work uncommitted for review |

### review

| Component | Trigger | Description |
| --- | --- | --- |
| `project-analyst` (agent, "Nigel") | Task tool, or "what would a senior dev criticize?" | Holistic review of a project's polish, DX, docs, naming, packaging, and accessibility (WCAG 2.2 AA). Cross-stack |
| `project-audit` (skill) | `/review:project-audit`, or "audit the project" | Two-reviewer release audit pairing Nigel with an external **Codex** code review; their findings deliberately barely overlap |

### write-manual

| Component | Trigger | Description |
| --- | --- | --- |
| `write-manual` (skill) | `/write-manual:write-manual`, or "write manual" | Multi-agent pipeline (Haiku scouts → Sonnet research → Opus writing → Sonnet verify/translate) producing accessible, WCAG 2.2 AA desktop-app user manuals |

### dotnet-tools

| Component | Trigger | Description |
| --- | --- | --- |
| `dotnet-style-corrector` (agent) | Task tool, or "check my C# style" | Checks C# against Oire .NET coding standards and `.editorconfig`. Stack-specific, hence its own plugin |

### conventions (opt-in)

**Opinionated Oire conventions** enforced as `PreToolUse` hooks — organization
policy, not universal truths, so opt in only if you want them. (The other
plugins make no such assumptions and are meant for everyone.) When the plugin is
enabled, its `hooks.json` wires the two cross-platform hooks via `bash`; see
[`plugins/conventions/README.md`](plugins/conventions/README.md) for the full
story and the PowerShell/manual alternative.

| Hook | Fires on | Description |
| --- | --- | --- |
| `check-american-english` (cross-platform) | `Write`/`Edit`/`MultiEdit`/`NotebookEdit` | Blocks writes containing non-American spellings |
| `check-git-guard` (cross-platform) | `Bash`/`PowerShell` | Blocks git writes that destroy work — force/deleting/mirroring `push`, `--amend`, `rebase`, `reset --hard`, `restore`, destructive `checkout`, `clean -f`, bulk staging, `git mv`/`git rm`. Staging named paths, committing, and a plain `push` are allowed |
| `check-no-null-redirect` (Windows-only) | `Bash`/`PowerShell` | Blocks null-device redirects that leave stray `nul` files. Shipped but not auto-wired (a plugin can't branch on OS); wire manually on Windows |

## Updating plugins

Installed plugins don't update themselves. To pull the latest from the
marketplace, refresh the catalog and then update the plugin:

```
/plugin marketplace update debussy
/plugin update planning@debussy
```

Or enable auto-update for a plugin from the `/plugin` menu.

## Manual hook wiring (optional)

If you prefer the native **PowerShell** hook runners, or want the hooks
always-on without enabling the plugin, wire them through `settings.json`
instead:

1. Run `install.ps1` (Windows) or `install.sh` (Unix) to copy the hook scripts
   into `~/.claude/hooks/`.
2. Merge the matching snippet from [`settings/`](settings) into your
   `~/.claude/settings.json` under `hooks.PreToolUse`, then restart Claude Code.

**Windows + the plugin?** If you enable the `conventions` plugin for the
cross-platform hooks and only need to add the Windows-only
`check-no-null-redirect`, you don't have to copy anything: wire a single
`settings.json` entry pointing straight at the plugin's own shipped script, so it
tracks marketplace auto-updates instead of drifting from a copy. Just don't also
wire the cross-platform PowerShell runners while the plugin is enabled, or
`check-american-english` and `check-git-guard` will fire twice. Full recipe in
[`plugins/conventions/hooks/README.md`](plugins/conventions/hooks/README.md).

`sync.*` pulls in-place hook edits back into the repo; `uninstall.*` removes the
copied hooks (by name — it never touches your other hooks).

## Conventions enforced here

debussy is developed with its own **conventions** plugin enabled, so the repo
follows its own rules: **American English everywhere**, **no null-device
redirects on Windows**, and **no Claude-side git writes that destroy work**
(Claude may stage named paths, commit, and push; it never force-pushes, rewrites
history, discards changes, or uses `git mv`/`git rm`). Documenting a
spelling checker means occasionally describing non-American spellings without
spelling them out — see the authoring notes in
[`plugins/conventions/hooks/README.md`](plugins/conventions/hooks/README.md).

## Acknowledgments

The **planning** plugin (brainstorm, plan-make, plan-review, plan-exec) is
adapted from [**cc-thingz** by Umputun](https://github.com/umputun/cc-thingz) —
a mature, generous Claude Code marketplace that's well worth using directly.
That material originates from his MIT-licensed work; his copyright notice is
retained in [NOTICE](NOTICE). Thank you, Eugene.

## License

debussy is licensed under [Apache-2.0](LICENSE). It incorporates MIT-licensed
material from [cc-thingz](https://github.com/umputun/cc-thingz) (the `planning`
plugin); MIT and Apache-2.0 are compatible, and Umputun's MIT notice is retained
in [NOTICE](NOTICE) as required. Copyright 2026 André Polykanine (Oire).
