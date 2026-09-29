---
name: project-audit
description: "Run a two-reviewer audit of the current project: Codex (code-level review via external CLI) and Nigel (project-analyst agent, holistic polish/DX/a11y review), then implement the findings the user picks. Use when the user says 'project-audit', 'audit the project', 'audit this project', 'pre-release audit', 'release readiness check', 'polish pass', 'Nigel + Codex review', 'combined review', or 'quality audit'. Also use to pick up a started audit: 'continue the audit', 'resume the audit', 'where did we get to on the audit'. Mode keywords the user may include: 'nigel-first', 'codex-first', 'nigel-only', 'codex-only' — pass the matched keyword as the skill argument."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash:*), Bash(command -v codex), Bash(git status:*), Bash(git fetch:*), Bash(git switch:*), Bash(git add:*), Bash(git commit:*), Bash(git pull --ff-only), Bash(git push), Bash(git push -u origin HEAD), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(gh auth status), Bash(gh pr create:*), Bash(gh pr view:*), Agent, Workflow, AskUserQuestion, TaskCreate, TaskUpdate
---

# project-audit

A release audit by two reviewers with complementary strengths:

- **Codex** (external CLI) reviews *code*: bugs, security, race conditions, error
  handling. Best on diffs.
- **Nigel** (the `review:project-analyst` agent) reviews the *project*: docs
  accuracy, DX, naming, packaging, accessibility, release-readiness.

Nigel's findings are mostly non-code (README fixes, metadata, a11y gaps) and
Codex's are code-level. They barely overlap, which is the point, so don't ask
either one to do the other's job.

The audit is done when both reviewers selected by the mode have reported, the
user has triaged every finding, the chosen ones are implemented and verified,
and the work is committed as far as the `git` setting goes.

Keep user-visible output accessible: plain prose and bullet lists, no tables,
ASCII diagrams, or box-drawing characters. The same goes for what subagents
return. Give counts in a sentence ("seven serious, three moderate"), not as a
column of numbers.

## Arguments

`$ARGUMENTS` selects the mode:

- `nigel-first` (suits release audits) — Nigel, implement the chosen findings,
  then Codex reviews the resulting diff.
- `codex-first` (suits unreviewed work in progress) — Codex on the existing
  diff, implement the chosen findings, then Nigel audits the whole project.
- `nigel-only` — skip Codex.
- `codex-only` — skip Nigel.

With no argument, run `git status --short` and check whether the current branch
is ahead of the base branch. Uncommitted changes or unmerged commits suggest
`codex-first`; otherwise suggest `nigel-first`. Confirm with AskUserQuestion.

If `command -v codex` finds nothing, say "Codex not installed; skipping Codex
phases" and continue as `nigel-only`.

## Git

Read `${CLAUDE_PLUGIN_ROOT}/skills/project-audit/references/settings.md` and
`git.md` beside it for the settings, branching, commit, push, and pull request
rules. What is specific to an audit:

- Before anything else, note which files already have uncommitted changes
  (`git status --porcelain`). They are the user's work: the audit reviews them
  but never commits them. If a chosen fix has to touch one, the fixer edits it
  and leaves it uncommitted, and the final report says so.
- If you're on the base branch, cut `audit-<YYYY-MM-DD>` from it as git.md
  describes. If you're already on another branch, stay there; that branch is what
  is being audited.
- Each implemented triage round is one commit, made by the fixer (Step 4), with
  a message naming the reviewer and what was fixed.
- Push and open the pull request at the end, as far as the `git` setting says.
  If you stayed on an existing branch that already has an open pull request, push
  to it and don't open another.

## Audit record

The audit keeps a record at `.claude/project-audit/<branch>.md`: every finding
with a stable id, and what the user decided about it.
`${CLAUDE_PLUGIN_ROOT}/skills/project-audit/references/audit-record.md` gives
its format. Update it as you go, not at the end; it is what a resumed audit
starts from and what a later reviewer is told to leave alone.

To resume, list `.claude/project-audit/*.md`. Take the record for the current
branch, or ask which one if there are several and none matches; switch to its
branch if you're not on it. Read it, tell the user in a few lines where the
audit stands, and carry on from the first finding still `pending`, or from the
mode's next step if none is.

## Prompts

Read every prompt through the override chain, never directly:
`bash ${CLAUDE_PLUGIN_ROOT}/skills/project-audit/scripts/resolve-file.sh prompts/nigel-focus.md`.
A project can override any of them with a file of the same relative path under
`.claude/project-audit/` (for example `.claude/project-audit/prompts/codex-audit.md`).
For `codex-audit.md`, pass on only its `## Prompt` section, not the notes above it.

## When to ask, when to proceed

Proceed without asking through reviewing, implementing clear-cut findings,
building, testing, and committing. Stop and ask when:

- the mode isn't given (see Arguments);
- the user has to triage a reviewer's findings (every round);
- a finding needs a design decision or is ambiguous;
- a fix breaks the build or tests and the right repair isn't obvious;
- a push is rejected or the pull request can't be created.

## Process

### Step 1. Mode and task list

Resolve the mode, then create tasks with TaskCreate for its phases, e.g. for
`nigel-first`: Nigel audit, triage Nigel findings, implement Nigel fixes, Codex
review of the fixes, triage Codex findings, implement Codex fixes, push and pull
request. Mark each `in_progress` when it starts and `completed` when done, and
skip any the user opts out of.

Then create the audit record with the branch, base, mode, date, and the files
that already had the user's uncommitted changes. Add the windows answer when
you have it.

### Step 2. First reviewer

**Nigel** (`nigel-first`, `nigel-only`). If the project has a user interface,
first ask once whether Nigel may open windows. A launched desktop app, or a
browser that is not headless, takes focus from whatever the user is doing,
which matters with a screen reader. Offer "headless only" (web apps are still
checked in Playwright's headless shell; desktop visuals are marked suspected)
and "windows allowed, now". Put the answer into the prompt's `WINDOWS_RULE`:
either "Do not open any window: headless browser only; mark what you could not
see as suspected." or "Windows are allowed during this audit: batch every
launch into one session and close what you open."

Then run the workflow, which fans Nigel out
over four focus groups (code and DX, accessibility and visuals, docs and
packaging, tests and security) and has a skeptic per group try to refute each
finding against the files:

```
Workflow({
  scriptPath: "${CLAUDE_PLUGIN_ROOT}/skills/project-audit/workflows/nigel.js",
  args: {
    nigel: <resolved prompts/nigel-focus.md, WINDOWS_RULE filled>,
    skeptic: <resolved prompts/nigel-skeptic.md>
  }
})
```

It returns `confirmed`, `suspected`, and `refuted` findings, the `coverage`
each group reported, and any `failedGroups` whose area went uncovered. Give the
findings ids `N1`, `N2`, and so on, continuing from the last `N` id in the
record, and add them to the record as `pending`, with the uncovered areas. Treat the script as a template: to
narrow the audit (say, the user only asked about docs), pass `groups` with just
those focus areas.

Without the Workflow tool, launch a single Nigel instead:

```
Agent(
  subagent_type: "review:project-analyst",
  description: "Nigel project audit",
  prompt: "Perform a full release-readiness audit of this project. Windows: <WINDOWS_RULE>"
)
```

**Codex** (`codex-first`, `codex-only`). Pick the scope:
- Branch ahead of the base branch: `git diff <base>...HEAD`.
- Otherwise, uncommitted changes: `git diff HEAD`.
- Otherwise: the whole project, passed as the literal `FULL PROJECT`.

Resolve `prompts/codex-audit.md` and substitute `DIFF_COMMAND`. Write
its `## Prompt` section to `.claude/project-audit/codex-prompt.txt` with the
Write tool. The prompt contains backticks, so it must never pass through the
shell as text: not inline in the command, not through `echo` or an unquoted
heredoc. Then run it in the background (`run_in_background: true`; you are
notified when it finishes):

```
bash ${CLAUDE_PLUGIN_ROOT}/skills/project-audit/scripts/run-codex.sh .claude/project-audit/codex-prompt.txt
```

A non-zero exit, empty output, or output with neither `NO ISSUES FOUND` nor a
single critical, major, or minor tag means Codex failed, not that the code is
clean. Say "Codex review failed", quote its first line of output, and ask
whether to continue with Nigel alone.

Codex's findings get the same skeptic treatment as Nigel's before you see
them. Parse each finding line into `{ id, file, line, severity, description }`,
with ids `C1`, `C2`, and so on (continuing from the last `C` id in the
record), severity one of critical, major, or minor, and an empty `file` when
Codex gave no location. Then run:

```
Workflow({
  scriptPath: "${CLAUDE_PLUGIN_ROOT}/skills/project-audit/workflows/codex-verify.js",
  args: {
    skeptic: <resolved prompts/codex-skeptic.md>,
    findings: <the parsed findings>
  }
})
```

It returns `confirmed`, `suspected`, and `refuted` findings, each with the
skeptic's note. Without the Workflow tool, spawn one `general-purpose` agent
with the skeptic prompt and all the findings in place of `FINDINGS`, and sort
its verdicts the same way. Skip this when Codex answered `NO ISSUES FOUND`.
Add the findings to the record as `pending`, the refuted ones with the
skeptic's reason.

**A reviewer that runs again.** When the record already holds findings (the
second reviewer in Step 5, a re-run in Step 6), add a paragraph to the end of
the reviewer's prompt, the Nigel prompt before it goes into the workflow's
`nigel` argument and the Codex prompt before you write it to its file: "These
were already reported in this audit and either declined by the user or refuted
on checking. Don't report them again unless the code they point at has changed
since:", followed by the declined and refuted findings, one line each with what
and where. If one comes back anyway, show it in triage marked as reported
before, with the earlier decision, instead of dropping it.

### Step 3. Triage

Present the findings as a compact bullet list grouped by severity, numbered so the
user can refer to them. List confirmed findings first, then suspected ones
marked as such with what would confirm them, then a one-line count of refuted
findings (offer their reasons on request). For Nigel, also name any failed focus
group, and list the coverage entries marked not tested, since those are areas
nobody looked at.

Then ask with AskUserQuestion which to implement:
- all critical and serious (or major) findings;
- everything, including minor findings and nitpicks;
- a custom selection, by number;
- none of this reviewer's findings — move on;
- stop the audit.

Don't pre-filter or quietly drop findings; the user decides. Record each
decision as the user makes it: the chosen findings stay `pending` until the
fixer reports, and the rest become `declined`.

### Step 4. Implement

If a chosen finding plainly needs a design decision, ask about it now, and put
the answer next to the finding. Then spawn one `general-purpose` fixer with the
resolved `prompts/fixer.md`, placeholders filled as its notes say. The fixer
works from the chosen findings alone, which keeps the fixes and the build
output out of this conversation.

From its report:
- Record each finding as `implemented in <commit>` or `not fixed: <why>`.
- A finding marked `DECISION:` needs the user: ask, then spawn another fixer for
  those findings, with the answers added.
- If validation failed, show what failed and ask how to proceed.
- Run `git status --porcelain`. Paths outside `.claude/` that are uncommitted
  and were not the user's to begin with are missing from the diff the next
  reviewer reads, so warn about them.

Tell the user one line per finding: fixed, or not fixed and why.

### Step 5. Second reviewer

- `nigel-first`: run Codex on the diff of the fixes, skeptic included, as in
  Step 2. Skip it if the fixes
  produced no diff or touched only docs and metadata, where Codex has little to
  add; ask if unsure.
- `codex-first`: run the Nigel workflow on the updated project.
- `*-only`: skip this step.

Then triage (Step 3) and implement (Step 4) its findings.

### Step 6. Optional third pass

Only if Step 4 changed substantial code (more than a few lines of non-doc
changes), ask whether to run the first reviewer once more on the new diff. At
most one re-run: looping until clean is plan-exec's job, not this skill's.

### Step 7. Finish

Push and open the pull request as the `git` setting says, then report:
- which reviewers ran and how many findings each produced (confirmed,
  suspected, and refuted);
- which findings were implemented and which were skipped, and that they stay
  in the audit record (give its path) to revisit;
- the branch, commit subjects, and pull request URL, and any files left
  uncommitted because they held the user's own changes.
