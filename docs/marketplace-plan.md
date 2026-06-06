# Marketplace + plugin design

Status: **realized.** debussy is a marketplace of five plugins. This doc records
the reasoning so the structure isn't mysterious later.

## Two distribution mechanisms, on purpose

- **Plugins / marketplace** — the primary path. `.claude-plugin/marketplace.json`
  exposes plugins installed via `/plugin install <name>@debussy`. Plugins are
  selective (enable per machine/project), versioned, cleanly removable, and
  shareable.
- **Manual file copy** — a secondary path for the convention *hooks* only
  (`install.*` + `settings.json`). Kept because some users (the author on a
  no-Git-Bash Windows box) prefer the native PowerShell hook runners, which the
  plugin's bash-based `hooks.json` doesn't use.

## Plugin decomposition — grouped by cohesion

The unit is "things that actually depend on each other," not a catch-all domain:

- **planning** — brainstorm + plan-make + plan-review + plan-exec. They chain
  and share `docs/plans/`. brainstorm is the design step at the front.
- **review** — project-audit + project-analyst. The skill invokes the agent.
- **write-manual** — standalone pipeline; only relevant for desktop apps.
- **dotnet-tools** — stack-specific; install only in .NET projects.
- **conventions** — the hooks. These are *personal policy*, not a feature, so
  they're a single opt-in plugin rather than scattered across feature plugins
  (a hook in the "planning" plugin would only fire while planning — wrong for an
  always-on rule).

## Why hooks are their own plugin (and partly manual)

Hooks are cross-cutting policy, orthogonal to features. Two wrinkles shaped the
design:

1. **OS applicability.** `check-no-null-redirect` is Windows-only (on Unix,
   `/dev/null` is correct). A plugin `hooks.json` is static and can't branch on
   OS, so the conventions plugin auto-wires only the two cross-platform hooks
   and ships the Windows-only one unwired, documented for manual wiring.
2. **Runtime.** The plugin wires hooks via `bash` + the `.sh` runners (portable;
   degrade gracefully without `jq`). The native PowerShell runners remain
   available through the manual `settings.json` path for those who prefer them.

## Conventions on conventions

- A marketplace is inert until added (`/plugin marketplace add`), so shipping
  `marketplace.json` is safe.
- Keep `source` paths repo-relative so local checkouts and the GitHub-hosted
  form both resolve.
- New feature → put it in the cohesive plugin and list it in `marketplace.json`.
  New always-on rule → it's a hook in `conventions`, with the windows-only vs
  cross-platform split respected.

## Possible future work

- Split `brainstorm` into its own plugin if it's wanted without the planning
  trio.
- A small OS-detecting dispatcher so the conventions plugin could auto-wire the
  PowerShell runners on Windows and `.sh` elsewhere from one `hooks.json`.
