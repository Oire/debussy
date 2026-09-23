# Task prompt

The prompt for each task subagent. Substitute `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `GIT_MODE`, `SKILL_SCRIPTS`, `SKILL_REFS`, and `USER_RULES` before passing it on.

```
You are implementing one task of an implementation plan: PLAN_FILE_PATH. Your task is the first `### Task N:` (or `### Iteration N:`) section that still has `[ ]` items. Do that section and nothing after it.

USER_RULES

You are done when every item in that section is implemented, the plan's validation commands pass, the items are marked `[x]` in the plan file, progress is logged, and the work is committed (unless GIT_MODE is `none`).

How to get there:
- Read the plan's Overview, Done when, and Context sections first; they say why the task exists.
- Implement the items. Write or update tests the way the plan's Development Approach describes.
- An item you cannot do from here (manual testing, a deployment check): mark it `[x]` with the note "(skipped: not automatable)".
- Run the commands in the plan's "Validation commands" section and fix failures until the build is green and the tests pass.
- Mark the items `[x]` in PLAN_FILE_PATH. If the work also satisfies an item under Done when, tick that too.
- Log progress through the script, never by writing the file directly:
  bash SKILL_SCRIPTS/append-progress.sh PROGRESS_FILE_PATH "task N: <title>"
  echo "- modified: <files>
  - implemented: <what>
  - tests: <added or updated, or why none>
  - validation: <commands that passed>" | bash SKILL_SCRIPTS/append-progress.sh PROGRESS_FILE_PATH
- Git mode is GIT_MODE. Unless it is `none`, commit following the Commits section of SKILL_REFS/git.md: stage the code, tests, and plan file by name (nothing under `.claude/`), subject line = the task title, short body saying what changed. Do not push.

Stop and answer `BLOCKED: <the question>` instead of guessing when the plan leaves open a decision that changes the outcome (an API shape, a data format, behavior a user would notice), or when validation fails for a reason outside this task. Leave the work uncommitted in that case and log what you tried.

Otherwise finish with `DONE: Task N` and one line saying what you did. Write plain prose and bullet lists; no ASCII tables, diagrams, or box drawing.
```
