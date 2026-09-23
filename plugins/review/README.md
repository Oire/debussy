# review (plugin)

Project review and release-readiness auditing.

## Contents

- **`project-analyst`** (agent, "Nigel") — an insufferably meticulous senior
  architect who reviews a project holistically: docs accuracy, DX, naming,
  packaging, accessibility (WCAG 2.2 AA), visual polish, and anything that looks
  unprofessional. Cross-stack (.NET, PHP, JS/TS, frontend, desktop); the
  per-stack checklists live in `references/project-analyst/` and are read only
  for the stack Nigel detects. Every finding carries its evidence and a status:
  **confirmed** (read in the code or seen on screen) or **suspected** (inferred,
  with what would confirm it). When the app can be run, Nigel runs it and looks
  at screenshots rather than guessing at the layout from code.
- **`project-audit`** (skill) — a two-reviewer release audit pairing Nigel with
  an external **Codex** CLI review (code-level bugs, security, races). Their
  findings deliberately barely overlap. The Nigel phase is a workflow
  (`skills/project-audit/workflows/nigel.js`): four Nigels, each on one focus
  group, and a skeptic per group that tries to refute their findings against the
  files before you see them. Without the Workflow tool it falls back to a single
  Nigel.

The skill calls the agent, so they are packaged together.

## Git behavior

`project-audit` commits each round of fixes you choose to implement and, by
default, pushes the branch and opens a pull request. On the base branch it
first cuts `audit-<date>` from the up-to-date base; on any other branch it stays
put, since that is the branch being audited. Files that already had your
uncommitted changes are never committed. Nothing mentions AI or Claude.

The behavior is set in `.claude/debussy.json` (project) or
`~/.claude/debussy.json` (user); see
[`skills/project-audit/references/git.md`](skills/project-audit/references/git.md).
Set `"git": "none"` to keep the old leave-everything-uncommitted behavior.

## Install

```
/plugin marketplace add Oire/debussy
/plugin install review@debussy
```

Note: `project-audit` shells out to an external `codex` CLI; install that
separately if you want the code-level half of the audit. Opening pull requests
uses the GitHub CLI (`gh`); without it the branch is pushed and you get the
compare URL.
