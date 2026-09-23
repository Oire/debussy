---
name: plan-exec
description: "Execute an implementation plan from docs/plans/ task by task in isolated subagents, review the result, and open a pull request. Use when the user says 'plan-exec', 'execute plan', 'run plan', 'implement the plan', or wants a plan file carried out."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash:*), Bash(git status:*), Bash(git fetch:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(git push -u origin:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh auth status), Bash(gh pr create:*), Agent, Workflow, AskUserQuestion, TaskCreate, TaskUpdate
---

# plan-exec

Carry out a plan written by `/planning:plan-make`: each task in a fresh subagent, then a review, then a pull request. Plans live in `docs/plans/<number>-<name>.md` (`001-add-login.md`, `1234-fix-retry.md`).

The run is done when:
- every Task section in the plan is checked off
- the review has come back clean or run out of rounds
- the plan has moved to `docs/plans/completed/`
- the work has gone as far as the git setting allows, up to an open pull request

You are the orchestrator. Code work happens in subagents so your own context stays small over a long run. You track task numbers, retries, and review results, and you do not read or fix code yourself.

Write plain prose and short bullet lists to the user, and keep that in every prompt you pass on: no ASCII tables, diagrams, or box drawing.

## When to stop and ask

Keep going without asking between tasks, between review rounds, when a finding is refuted, and when Codex is not installed. Stop and ask the user when:
- the working tree has changes that are not this plan's
- you are on a branch that is neither the base branch nor this plan's branch
- a task answers `BLOCKED`
- a task fails twice
- a push or pull request fails
- the review still reports critical problems after its last round

## Setup

Arguments: `$ARGUMENTS` is the plan path. Without it, list `docs/plans/*.md` (not `completed/`): use the only one, or ask which.

1. Read the plan and count its `### Task N:` (or `### Iteration N:`) sections.
2. Read `${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/references/git.md` and resolve the settings it describes: git mode, base branch, attribution.
3. Load custom rules: `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/resolve-rules.sh planning-rules.md ${CLAUDE_PLUGIN_DATA}`. Non-empty output becomes `USER_RULES` as "ADDITIONAL CUSTOM RULES:" followed by the content; otherwise `USER_RULES` is empty. See `references/custom-rules.md`.
4. Branch. The plan's branch is its file name without `.md` and without the leading number (`001-add-login.md` becomes `add-login`). `/planning:plan-make` normally created it already.
   - On that branch: carry on. This covers a fresh start and a resumed run alike.
   - On the base branch: cut the plan's branch as `git.md` describes. If the plan file itself is uncommitted, it comes along; commit it first as "Add plan: <title>".
   - On any other branch: ask whether to stack the plan on it or cut the plan's branch from the base.
   - With git mode `none`, skip all of this and stay where you are.
5. Progress file: `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/init-progress.sh .claude/exec-plan/progress/<plan-stem>.txt <plan-path> <branch>`, then tell the user its path. Append to it only through `scripts/append-progress.sh`. `references/prompts/progress-file.md` says what goes in.
6. Create a task-list entry per plan task, plus "Review", "Codex review", "Final re-check", and "Finish". Mark each in progress and completed as you go.

## Prompts

Read every prompt and lens file through the override chain, never directly: `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/resolve-file.sh prompts/task.md`. A project can override any of them under `.claude/exec-plan/`. For `task.md`, `fixer.md`, and `codex-review.md`, pass on only the prompt itself (the fenced block or `## Prompt` section), not the notes above it.

Substitute these placeholders before a prompt leaves your hands, because subagents start with no context:
- `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `DEFAULT_BRANCH` (the base branch), `GIT_MODE`, `USER_RULES`
- `SKILL_SCRIPTS` = `${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts`
- `SKILL_REFS` = `${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/references`
- `DIFF_COMMAND` in the Codex prompt only

`FINDINGS` and `FINDINGS_LIST` are filled per round, by the review workflow or by you in the Codex loop.

## Tasks

Repeat until no Task section has a `[ ]` item (a limit of 50 subagent runs guards against a loop):

1. Re-read the plan; the subagents edit it. Take the first Task section with `[ ]` items.
2. Tell the user the task number, title, and its open items as a plain list.
3. Spawn a `general-purpose` subagent with the resolved `prompts/task.md`.
4. Re-read the plan. If the section is fully checked, log it, report "Task N completed" in one line, and continue.
5. If the subagent answered `BLOCKED: <question>`, ask the user, then rerun the task with the answer added to the prompt.
6. Otherwise, retry once with a fresh subagent and put the failure it reported (errors, failing tests) in the prompt. A second failure stops the run.

Progress is decided by the checkboxes in the plan, not by what a subagent says.

## Review

The review runs as a workflow that ships with this skill: `${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/workflows/review.js`. In each round, reviewers read the branch in parallel, each through one lens. A skeptic per file then tries to refute their findings, and a fixer handles what survives, validates, and commits. Later rounds re-check critical problems only. Run it by calling the Workflow tool (load it through ToolSearch if it is deferred) with `scriptPath` set to that path and these `args`:

- `preamble`: resolved `prompts/reviewer.md`
- `criticalNote`: resolved `prompts/critical-note.md`
- `verifier`: resolved `prompts/verifier.md`
- `fixer`: resolved `prompts/fixer.md`
- `lenses`: `[{ name, prompt }]`, each from `agents/<name>.txt`. Scale the lenses to the change. Under about 150 changed lines (`git diff --shortstat DEFAULT_BRANCH...HEAD`), use `quality`, `implementation`, and `testing`. Above that, add `simplification`, `documentation`, and `smells`.
- `criticalLenses`: `["quality", "implementation"]`
- `maxRounds`: 3

The workflow returns its rounds: what was found, confirmed, refuted (with reasons), and fixed. Tell the user a short list per round, including the refuted findings and why, so nothing is dropped silently. Append the rounds to the progress file.

If the Workflow tool is not available, do the same by hand: spawn the lens reviewers in parallel with the Agent tool, then give all their findings to one fixer. The fixer checks each finding before fixing it. After that, run re-check rounds with the critical lenses until clean or three rounds in all.

## Codex review

Skip this if `command -v codex` finds nothing, and say so. Otherwise, loop up to three rounds:
1. Record `git rev-parse HEAD`.
2. Run the resolved `prompts/codex-review.md` with `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/run-codex.sh "<prompt>"` in the background. You are notified when it finishes, so do not poll.
3. On `NO ISSUES FOUND`, the loop is done.
4. Otherwise, show the findings as a short list, spawn a fixer with them as `FINDINGS_LIST`, and show its report.

## Final re-check

Run the review workflow once more with `startCritical: true` and `maxRounds: 2`. This makes sure the Codex fixes did not break anything.

## Finish

1. Move the plan into `docs/plans/completed/`, creating the directory if needed. Unless git mode is `none`, commit the move as "Complete plan: <title>", staging the old and the new path by name.
2. Push and open the pull request as `git.md` describes, according to the git mode. Title: the plan title. Body:
   - what the change does and why, from the plan's Overview
   - the tasks completed
   - the review summary (rounds, what was fixed, what was refuted)
   - the validation commands that passed
   - the plan's Post-Completion items, as things for the reviewer to check by hand
3. Append "completed" to the progress file.
4. Report to the user: tasks done, review outcome, the branch, and the pull request URL. With git mode `none`, say instead that the changes are uncommitted in the working tree.
