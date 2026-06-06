# review (plugin)

Project review and release-readiness auditing.

## Contents

- **`project-analyst`** (agent, "Nigel") — an insufferably meticulous senior
  architect who reviews a project holistically: docs accuracy, DX, naming,
  packaging, accessibility (WCAG 2.2 AA), and anything that looks
  unprofessional. Cross-stack (.NET, PHP, JS/TS, frontend, desktop).
- **`project-audit`** (skill) — a two-reviewer release audit pairing Nigel with
  an external **Codex** CLI review (code-level bugs, security, races). Their
  findings deliberately barely overlap.

The skill calls the agent, so they are packaged together.

## Install

```
/plugin marketplace add Oire/debussy
/plugin install review@debussy
```

Note: `project-audit` shells out to an external `codex` CLI; install that
separately if you want the code-level half of the audit.
