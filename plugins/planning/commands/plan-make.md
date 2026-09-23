---
description: Create structured implementation plan in docs/plans/
argument-hint: describe the feature or task to plan
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Agent, Skill, EnterPlanMode, TaskCreate, TaskUpdate, TaskList
---

# Implementation plan

Write an implementation plan to `docs/plans/<number>-<name>.md`, on a fresh branch, ready for `/planning:plan-exec`. The number is the issue number if the request names one; otherwise the next free three-digit number in `docs/plans/` (`001`, `042`). The name is short, lowercase, and hyphenated.

The plan is done when it:
- says what finished looks like
- lists the commands that prove it
- breaks the work into tasks a fresh subagent can carry out one at a time without asking what you meant

## 1. Understand the request

Work out what kind of change this is (feature, bug fix, refactor, migration) and send an Explore agent for the context that kind needs:
- for a feature: the code it touches and similar existing features to copy
- for a bug: the failure, the code path, and recent changes there
- for a refactor or migration: every affected file, its test coverage, and its dependents

Also find the project's build, test, and lint commands, since the plan has to name them.

Then ask the user only what you cannot settle from the request and the code: the goal if it is ambiguous, scope boundaries, constraints, and anything that changes the design. Put the questions in one AskUserQuestion call, with multiple choice and a recommended answer where you can. If nothing is unclear, say what you understood in a sentence or two and move on.

## 2. Choose an approach

When more than one approach is reasonable, give two or three with their trade-offs, lead with the one you recommend and why, and let the user pick. Skip this when there is one obvious path or the user already said how. When code would repeat, name the trade-off: duplication is simpler and uncoupled, an abstraction is DRY but adds complexity. Recommend one.

## 3. Branch

Read `${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/references/git.md` and resolve its settings. Unless the git mode is `none`, start the plan on a new branch cut from the up-to-date base branch, named after the plan without its number (`001-add-login.md` goes on `add-login`). If you are already on a branch other than the base, ask whether to stack the plan on it or start from the base.

## 4. Write the plan

Use this structure. `/planning:plan-exec` relies on the `### Task N:` headings and `[ ]` checkboxes, and its subagents read Overview, Done when, Validation commands, and Development approach.

```markdown
# <Plan title>

## Overview
What changes, what problem it solves, and how it fits the existing system.

## Done when
- [ ] <observable outcome, e.g. "a registered user can log in with email and password">
- [ ] <another outcome>
- [ ] all validation commands pass

## Validation commands
- build: `<command>`
- test: `<command>`
- lint or format check: `<command, if the project has one>`
- e2e: `<command, if the project has e2e tests>`

## Context
- files and components involved
- patterns to follow (with a file that shows each)
- dependencies

## Development approach
- One task at a time; the validation commands pass before the next task starts.
- Code changes come with tests for the new and changed behavior, success and error paths, unless the change is UI-only or the user said to skip tests. UI work in a project with e2e tests gets e2e tests in the same task.
- A test that cannot pass until a later task is still written now, marked with a comment naming that task.
- Keep backward compatibility unless the user asked for a breaking change.
- When scope changes, update this plan: new tasks get a "➕" prefix, blockers a "⚠️" prefix.

## Implementation steps

### Task 1: <what this task accomplishes, specifically>

**Files:**
- Create: `path/to/new_file`
- Modify: `path/to/existing`

- [ ] <specific change, naming the file>
- [ ] <specific change>
- [ ] tests for <behavior>: success cases
- [ ] tests for <behavior>: error and edge cases
- [ ] validation commands pass

### Task N: Update documentation
- [ ] README, if users will do anything differently
- [ ] CLAUDE.md, if the change sets a pattern or gotcha the next agent needs

## Technical details
Data structures, formats, and processing flow, where the tasks need them.

## Post-completion
Things outside this codebase, with no checkboxes: manual and accessibility testing, changes needed in consuming projects, deployment configuration.
```

Size each task as one logical unit (a function, an endpoint, a component), usually around five checkboxes, with tests as their own items. A task named "Core logic" is too vague for a subagent to act on; say what the logic does.

## 5. Commit and hand off

Unless the git mode is `none`, commit the plan on its branch as "Add plan: <title>". Do not push yet; plan-exec pushes when the work is done. Then tell the user the plan path and branch, and ask what's next:

- **Auto review**: run the `planning:plan-review` agent on the plan, apply the fixes the user agrees with, commit them, and ask again.
- **Manual review**: the user edits the plan in their editor. When they are done, re-read it, raise anything that no longer fits together, commit, and ask again.
- **Start implementation**: invoke the `planning:plan-exec` skill with the plan path.
- **Done**: stop here.
