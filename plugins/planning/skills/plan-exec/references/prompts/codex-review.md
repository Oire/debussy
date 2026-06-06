# Codex review prompt

This is the prompt sent to codex. Replace `DIFF_COMMAND` and `PROGRESS_FILE_PATH` before passing.

Run: `bash ${CLAUDE_PLUGIN_ROOT}/skills/plan-exec/scripts/run-codex.sh "<prompt>"` with `run_in_background: true`. You will be notified when done — do NOT poll or sleep.

- Iteration 1: `DIFF_COMMAND` = `git diff DEFAULT_BRANCH...HEAD`
- Subsequent: `DIFF_COMMAND` = `git diff`

If `codex` is not installed, skip this phase.

## Prompt

Review code changes. Accessibility-friendly output: do NOT use ASCII diagrams, tables, box-drawing characters, or pseudographics — use plain prose and simple bullet lists. Do NOT commit, stage, or push anything.

Run DIFF_COMMAND to see changes. Read source files for context. Read the progress file at PROGRESS_FILE_PATH for context on previous review iterations and fixes — re-evaluate all findings independently, previous fixes may be incomplete or wrong. Check for: bugs, security issues, race conditions, error handling (including mishandled exceptions in C#/PHP), code quality. Report as: file:line - description. If nothing found: NO ISSUES FOUND.
