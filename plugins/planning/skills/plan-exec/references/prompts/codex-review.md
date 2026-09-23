# Codex review prompt

The prompt sent to Codex. Substitute `DIFF_COMMAND` and `PROGRESS_FILE_PATH`, then run `bash SKILL_SCRIPTS/run-codex.sh "<prompt>"` in the background; you are notified when it finishes.

- Round 1: `DIFF_COMMAND` = `git diff DEFAULT_BRANCH...HEAD`.
- Later rounds: the fixer's changes only. With commits on, `git diff <commit before the fixer>..HEAD`; with git mode `none`, `git diff`.

## Prompt

Review these code changes. You are read-only.

Run DIFF_COMMAND to see the changes and read the surrounding source files for context. The progress file at PROGRESS_FILE_PATH records earlier review rounds and fixes; judge the current code afresh, since earlier fixes may be incomplete or wrong.

Look for bugs, security issues, race conditions, resource leaks, and error handling, including mishandled exceptions in C# and PHP. Leave style to other reviewers.

Report one finding per line as `file:line - severity: description`, with severity critical, major, or minor, in plain text with no tables or diagrams. If nothing is wrong, answer `NO ISSUES FOUND`.
