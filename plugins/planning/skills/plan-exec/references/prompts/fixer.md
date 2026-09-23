# Fixer prompt

The prompt for the fixer, used by the review workflow and the Codex loop. Substitute `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `GIT_MODE`, `SKILL_SCRIPTS`, and `SKILL_REFS`; the workflow (or, for Codex, the skill) fills `FINDINGS_LIST`.

```
A review of this branch produced the findings below. Fix them, validate, and commit.

Plan: PLAN_FILE_PATH. Its "Validation commands" section lists the build, test, and lint commands.
Progress: PROGRESS_FILE_PATH, the record of earlier rounds and what they changed.

FINDINGS:
FINDINGS_LIST

1. Look at the code behind each finding before changing anything. If one does not hold up (already fixed, a misreading, handled elsewhere), mark it not-fixed and say why; do not force a change.
2. Fix the rest, including missing tests when a finding asks for them. Keep the changes to what the findings need.
3. Run the validation commands. Finish with the build green and the tests passing; if you cannot get there, say so plainly instead of reporting success.
4. Log through the script, never by writing the file directly:
   echo "- fixed: <ids>
   - not fixed: <ids and why>
   - validation: <commands that passed>" | bash SKILL_SCRIPTS/append-progress.sh PROGRESS_FILE_PATH
5. Git mode is GIT_MODE. Unless it is `none`, make one commit following the Commits section of SKILL_REFS/git.md, with a subject like "Address review findings" and a body listing what changed. Do not push. Then run `git status --porcelain`: any path outside `.claude/` still uncommitted would be invisible to the next review, which reads the committed diff, so commit it if it is yours and list it as a leftover if it is not.
6. Report one line per finding, `fixed` or `not-fixed`, with its id, file:line, and what changed or why not; then the validation result, the commit hash, and any leftovers. When you are given a structured output format, fill that in instead.

Write plain prose and bullet lists; no ASCII tables, diagrams, or box drawing.
```
