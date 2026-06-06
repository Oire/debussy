# planning (plugin)

The idea-to-execution pipeline, as one cohesive plugin. These tools chain and
share the `docs/plans/<number>-<task>.md` convention:

1. **`brainstorm`** (skill) — collaborative, one-question-at-a-time conversation
   that turns a rough idea into a validated design.
2. **`plan-make`** (command) — writes a structured implementation plan to
   `docs/plans/`.
3. **`plan-review`** (agent) — read-only review of a plan for completeness,
   correctness, over-engineering, and convention adherence before any code.
4. **`plan-exec`** (skill) — executes the plan task by task, each in an isolated
   subagent, leaving all work uncommitted for manual review.

## Contents

- `skills/brainstorm/`
- `commands/plan-make.md`
- `agents/plan-review.md`
- `skills/plan-exec/` (with its `references/` and `scripts/` trees)

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
