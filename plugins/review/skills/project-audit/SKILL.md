---
name: project-audit
description: "Run a two-reviewer audit of the current project: Codex (code-level review via external CLI) and Nigel (project-analyst agent, holistic polish/DX/a11y review). Use when the user says 'project-audit', 'audit the project', 'audit this project', 'audit my project', 'run an audit', 'review before release', 'pre-release audit', 'release readiness check', 'polish check', 'polish pass', 'Nigel + Codex review', 'Codex + Nigel review', 'combined review', 'two-reviewer review', 'full review pass', 'quality audit', 'project quality review', or wants to combine an external Codex code review with a Nigel project-polish review. Mode keywords the user may include in free-form phrasing: 'nigel-first', 'codex-first', 'nigel-only', 'codex-only' — pass the matched keyword as the skill argument."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash:*), Bash(command -v codex), Bash(git diff:*), Bash(git rev-parse:*), Agent, AskUserQuestion, TaskCreate, TaskUpdate
---

# project-audit

Combined audit pass using two reviewers with complementary strengths:

- **Codex** (external CLI) — reviews *code* for bugs, security, race conditions, error handling. Best on diffs.
- **Nigel** (project-analyst agent) — reviews the *project* holistically for docs accuracy, DX, naming, packaging, accessibility, release-readiness.

Nigel's findings are often non-code (README fixes, missing metadata, a11y gaps). Codex's are code-level. They do not overlap heavily — that is the point.

## Accessibility-friendly output

Do NOT use ASCII diagrams, tables, box-drawing characters, or pseudographics in user-visible output (this applies to the orchestrator AND every subagent). Prefer plain prose and simple bullet lists.

## Key constraint — no git writes

This skill MUST NOT commit, stage, amend, rebase, squash, push, or create branches. Fixes are left uncommitted in the working tree for the user to review.

## Arguments

`$ARGUMENTS` selects the mode. If omitted, ask the user.

- `nigel-first` (default for release audits) — Nigel first, implement chosen findings, then Codex reviews the resulting diff.
- `codex-first` (default when there is unreviewed WIP) — Codex first on existing diff, implement chosen findings, then Nigel audits the whole project.
- `nigel-only` — skip Codex entirely.
- `codex-only` — skip Nigel entirely.

If `$ARGUMENTS` is empty: run `git status --short` and `git rev-parse --abbrev-ref HEAD`. If the tree has uncommitted changes or the current branch is ahead of the default branch, suggest `codex-first`. Otherwise suggest `nigel-first`. Use AskUserQuestion to confirm.

## Codex availability

Before running any Codex phase: `command -v codex`. If missing, report "Codex not installed — skipping Codex phases" and degrade to `nigel-only` for the rest of the run.

## Process

### Step 1. Resolve mode and create task list

Resolve the mode from `$ARGUMENTS` or prompt the user (see Arguments above).

Create tasks with TaskCreate matching the mode. Example for `nigel-first`:
- `Nigel audit` / `Triage Nigel findings` / `Implement Nigel fixes` / `Codex review of fixes` / `Triage Codex findings` / `Implement Codex fixes`

Update each to `in_progress` when starting and `completed` when done. Skip any phase the user opts out of during triage.

### Step 2. First-pass review

**If `nigel-first` or `nigel-only`** — launch Nigel:

```
Agent(
  subagent_type: "project-analyst",
  description: "Nigel project audit",
  prompt: "Perform a full release-readiness audit of this project. Report findings grouped by severity (critical / major / minor / nitpick) with file:line references where applicable. Accessibility-friendly output: plain prose and bullet lists, no ASCII tables or diagrams."
)
```

**If `codex-first` or `codex-only`** — run Codex. First, determine the diff command:
- If branch is ahead of default branch (check with `git rev-parse --abbrev-ref HEAD` and compare to `main`/`master`/`trunk`/`develop`): `git diff <default>...HEAD`
- Else if there are uncommitted changes: `git diff HEAD`
- Else: review the whole project (pass no diff; ask Codex to walk the tree).

Read `references/prompts/codex-audit.md`, substitute `DIFF_COMMAND` (or "FULL PROJECT" for the no-diff case), then:

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/project-audit/scripts/run-codex.sh "<resolved prompt>"
```

Use `run_in_background: true`. You will be notified when done — do NOT poll or sleep.

### Step 3. Triage — ask the user what to implement

After the first reviewer returns, present findings to the user as a compact bullet list grouped by severity. Then use AskUserQuestion to let the user pick which findings to implement. Options:

- Implement all critical + major findings
- Implement everything (including minor + nitpicks)
- Implement a custom selection — ask the user to list numbers
- Skip this review's fixes and move on
- Abort the audit

Never pre-filter or silently dismiss findings. The user decides.

### Step 4. Implement selected findings

For each selected finding, edit the relevant file(s) directly. Keep changes minimal and scoped to what was requested — no drive-by refactors. Do not commit.

If a finding is ambiguous or requires a design decision, use AskUserQuestion before implementing rather than guessing.

Report a short summary of what was changed (one line per file touched).

### Step 5. Second-pass review

**If mode is `nigel-first`**: now run Codex on the diff of the fixes. Skip if the fixes produced no diff or only touched docs/metadata — Codex has little to add there. Ask the user if unsure.

**If mode is `codex-first`**: now launch Nigel on the updated project.

**If mode is `*-only`**: skip this step.

Repeat Step 3 (triage) and Step 4 (implement) for the second reviewer's findings.

### Step 6. Optional third pass

Only offer this if Step 4 touched substantial code (more than a few lines of non-doc changes). Ask the user via AskUserQuestion:

- Run the first reviewer one more time on the new diff? (Yes / No)

Cap at one re-run. Do not loop indefinitely — that is plan-exec's job, not this skill's.

### Step 7. Completion

Report a summary to the user:
- Which reviewers ran
- How many findings each produced
- Which findings were implemented
- Which were skipped (so the user can revisit later)

Uncommitted changes remain in the working tree for the user to review and commit manually.

## Key rules

- Never commit, stage, amend, rebase, squash, push, or create branches
- Never dismiss or pre-filter reviewer findings — the user triages
- Never loop the two reviewers indefinitely — maximum one optional re-run (Step 6)
- Codex reviews code-level concerns; Nigel reviews project-level polish — do not ask either to do the other's job
- If Codex is not installed, degrade gracefully to Nigel-only
- Accessibility-friendly output in every user-visible message
- All AskUserQuestion prompts must present clear, numbered, actionable options
