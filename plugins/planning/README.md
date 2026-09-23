# planning (plugin)

The idea-to-execution pipeline, as one cohesive plugin. These tools chain and
share the `docs/plans/<number>-<task>.md` convention:

1. **`brainstorm`** (skill) — collaborative, one-question-at-a-time conversation
   that turns a rough idea into a validated design.
2. **`plan-make`** (command) — writes a structured implementation plan to
   `docs/plans/`, with a "Done when" finish line and the project's validation
   commands, on a new branch cut from the up-to-date base branch, and commits it.
3. **`plan-review`** (agent) — read-only review of a plan for completeness,
   correctness, over-engineering, and convention adherence before any code.
4. **`plan-exec`** (skill) — executes the plan task by task, each in an isolated
   subagent that commits its own work. Then it reviews the branch with a
   workflow (`skills/plan-exec/workflows/review.js`): reviewers read it in
   parallel through several lenses, a skeptic per file tries to refute each
   finding, and a fixer handles what survives. An optional Codex pass and a
   final critical-only re-check follow. It finishes by opening a pull request.

How far the git side goes (uncommitted, commit, push, pull request) and whether
anything mentions AI is set in `.claude/debussy.json`; see the repo README.

## Contents

- `skills/brainstorm/`
- `commands/plan-make.md`
- `agents/plan-review.md`
- `skills/plan-exec/` (with its `references/`, `scripts/`, and `workflows/` trees)

## Attribution

This plugin is adapted from [cc-thingz by Umputun](https://github.com/umputun/cc-thingz)
(MIT) — specifically his `planning` and `brainstorm` plugins. debussy's versions
are simplified and renamed, but the design and much of the scripting are his.
The MIT notice is in the repo-root [NOTICE](../../NOTICE).

## Install

```
/plugin marketplace add Oire/debussy
/plugin install planning@debussy
```
